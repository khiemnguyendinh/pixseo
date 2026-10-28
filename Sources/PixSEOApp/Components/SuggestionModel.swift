import AppKit
import Foundation
import Observation
import PixSEOCore

/// Name and alt-text suggestions for the first image: a fast one from text/labels in the
/// picture, and an Apple on-device AI one. Never blocks saving; results are cached per file.
@MainActor
@Observable
final class SuggestionModel {
    enum AIState: Equatable { case idle, running, finished, unavailable }

    private(set) var heuristic: NameSuggestion?
    private(set) var ai: NameSuggestion?
    private(set) var aiState: AIState = .idle
    /// Editable; copied to the clipboard after saving when the setting is on.
    var altText = ""

    private var analysis: ContentAnalysis?
    private var file: URL?
    private var aiTask: Task<Void, Never>?
    private var analysisTask: Task<Void, Never>?

    private struct CacheEntry {
        var analysis: ContentAnalysis
        var ai: NameSuggestion?
    }
    private static var cache: [String: CacheEntry] = [:]

    /// The suggestion used when the name field is left empty: AI first, then the fast one.
    var best: NameSuggestion? { ai ?? heuristic }

    var aiAvailable: Bool {
        SettingsStore.shared.preferences.aiEnabled && OnDeviceNameSuggester.status == .available
    }

    /// Analyzes `file`. AI runs automatically only for a single image whose name means nothing,
    /// because it takes ~10 s; otherwise the user asks for it with the ✨ button.
    func start(file: URL, isBatch: Bool, sourceIsMeaningless: Bool) {
        self.file = file
        let key = Self.cacheKey(file)
        if let cached = Self.cache[key] {
            apply(cached.analysis)
            ai = cached.ai
            aiState = cached.ai == nil ? .idle : .finished
            fillAlt()
        }
        let brandWords = ContentAnalyzer.words(fromBrandContext: SettingsStore.shared.preferences.brandContext)
        analysisTask = Task {
            if analysis == nil {
                let result = await Task.detached(priority: .userInitiated) { () -> ContentAnalysis? in
                    guard let preview = try? ImageSourceReader.preview(file, maxLongEdge: 1600) else { return nil }
                    return ContentAnalyzer.analyze(preview, customWords: brandWords)
                }.value
                guard !Task.isCancelled, let result else { return }
                apply(result)
                Self.cache[key] = CacheEntry(analysis: result, ai: nil)
                fillAlt()
            }
            if !isBatch, sourceIsMeaningless, ai == nil { requestAI(typed: "") }
        }
    }

    func requestAI(typed: String) {
        guard aiAvailable, let file, aiState != .running else {
            if !aiAvailable { aiState = .unavailable }
            return
        }
        guard let analysis else { return }
        aiState = .running
        let input = SuggestionInput(fileName: file.lastPathComponent, analysis: analysis,
                                    brandContext: SettingsStore.shared.preferences.brandContext, typed: typed)
        let key = Self.cacheKey(file)
        aiTask = Task {
            let result = await OnDeviceNameSuggester.suggest(input)
            guard !Task.isCancelled else { return }
            ai = result
            aiState = .finished
            if let result { Self.cache[key]?.ai = result }
            fillAlt()
        }
    }

    /// Stops work in flight (the user saved or closed).
    func cancel() {
        aiTask?.cancel()
        analysisTask?.cancel()
    }

    /// Copies the alt text if the setting is on; returns whether it did.
    func copyAltIfWanted() -> Bool {
        let alt = altText.trimmingCharacters(in: .whitespaces)
        guard SettingsStore.shared.preferences.autoCopyAlt, !alt.isEmpty else { return false }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(alt, forType: .string)
        return true
    }

    private func apply(_ analysis: ContentAnalysis) {
        self.analysis = analysis
        heuristic = HeuristicNameSuggester.suggest(analysis: analysis)
    }

    /// Fills the alt field from the best suggestion unless the user already wrote one.
    private func fillAlt() {
        if altText.isEmpty, let alt = best?.altText { altText = alt }
    }

    private static func cacheKey(_ url: URL) -> String {
        let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
        return "\(url.path)|\(values?.contentModificationDate?.timeIntervalSince1970 ?? 0)|\(values?.fileSize ?? 0)"
    }
}
