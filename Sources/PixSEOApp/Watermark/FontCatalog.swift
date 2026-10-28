import AppKit
import Observation
import PixSEOCore

/// Installed font families, split into those that can write Vietnamese and those that can't.
/// Checking hundreds of fonts takes a moment, so it runs once in the background.
@MainActor
@Observable
final class FontCatalog {
    static let shared = FontCatalog()
    private static let recentKey = "recentWatermarkFonts"

    private(set) var vietnamese: [String] = []
    private(set) var missingDiacritics: [String] = []
    private(set) var isLoaded = false
    private(set) var recent: [String] = UserDefaults.standard.stringArray(forKey: recentKey) ?? []

    func load() {
        guard !isLoaded else { return }
        isLoaded = true
        Task {
            let families = NSFontManager.shared.availableFontFamilies.filter { !$0.hasPrefix(".") }
            let split = await Task.detached(priority: .utility) { () -> ([String], [String]) in
                var ok: [String] = [], missing: [String] = []
                for family in families.sorted() {
                    if FontCoverage.supportsVietnamese(family: family) { ok.append(family) } else { missing.append(family) }
                }
                return (ok, missing)
            }.value
            vietnamese = split.0
            missingDiacritics = split.1
        }
    }

    func noteUsed(_ family: String) {
        recent = [family] + recent.filter { $0 != family }.prefix(4)
        UserDefaults.standard.set(recent, forKey: Self.recentKey)
    }
}
