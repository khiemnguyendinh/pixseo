import CoreGraphics
import Foundation
import Observation
import PixSEOCore

/// State behind the Quick Save panel. Decisions (advice, naming defaults, job planning) come
/// from PixSEOCore; this class only wires them to the UI.
@MainActor
@Observable
final class QuickSaveViewModel {
    let files: [URL]
    let skipped: [URL]
    private(set) var firstInfo: SourceImageInfo?
    private(set) var thumbnail: CGImage?

    let options: ExportOptions
    let naming: FileNaming
    let suggestions = SuggestionModel()
    let estimator: SizeEstimator
    /// Watermark preset to stamp while resizing; `nil` = none.
    var watermarkID: UUID?

    private let preferences: ExportPreferences

    init(intake: ResolvedIntake, preferences: ExportPreferences, service: ExportService) {
        files = intake.images
        skipped = intake.skipped
        self.preferences = preferences
        options = ExportOptions(preferences: preferences, width: intake.width)
        naming = FileNaming(files: intake.images)
        estimator = SizeEstimator(service: service)
        let presets = SettingsStore.shared.watermarkPresets.presets
        watermarkID = presets.contains { $0.id == preferences.quickSaveWatermarkID } ? preferences.quickSaveWatermarkID : nil
    }

    var isBatch: Bool { files.count > 1 }

    var watermarkPresets: [WatermarkPreset] { SettingsStore.shared.watermarkPresets.presets }

    var watermark: WatermarkSpec? {
        watermarkID.flatMap { id in watermarkPresets.first { $0.id == id }?.spec }
    }

    var recipe: EditRecipe { EditRecipe(resize: options.resize(), sharpen: options.sharpen, watermark: watermark) }

    var namer: OutputFileNamer { OutputFileNamer(suffix: preferences.sizeSuffix) }

    var outputSize: PixelSize? {
        firstInfo.map { OutputGeometry.outputSize(for: $0.pixelSize, resize: recipe.resize).size }
    }

    var previewFileName: String {
        naming.preview(outputSize: outputSize, format: options.format, namer: namer, suggested: suggestions.best?.title)
    }

    private var estimateKey: ExportJob? {
        files.first.map { SizeEstimator.key(source: $0, recipe: recipe, settings: options.settings) }
    }

    var advice: [ExportAdvisor.Advice] {
        if case .dimensionTooLarge(let max) = estimator.error { return [.dimensionTooLarge(max: max)] }
        return ExportAdvisor.advice(info: firstInfo, format: options.format, width: options.width,
                                    estimateWarnings: estimator.warnings(for: estimateKey))
    }

    /// SEO check for a single image (a batch has no single name or alt).
    var checklist: SEOChecklist? {
        guard !isBatch else { return nil }
        let slug = SEOSlugger.slugify(naming.singleName(suggested: suggestions.best?.title) ?? files.first?.deletingPathExtension().lastPathComponent ?? "")
        return SEOChecklist(bytes: estimator.reusable(for: estimateKey)?.data.count, outputSize: outputSize, slug: slug,
                            format: options.format, contentKind: firstInfo?.contentKind, frameCount: firstInfo?.frameCount ?? 1,
                            hasAltText: !suggestions.altText.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    var canSave: Bool { naming.isComplete }

    /// Reads the first image's details and thumbnail, then estimates and starts suggestions.
    func load() {
        guard let first = files.first else { return }
        suggestions.start(file: first, isBatch: isBatch, sourceIsMeaningless: naming.sourceIsMeaningless)
        Task.detached(priority: .userInitiated) {
            let info = try? ImageSourceReader.readInfo(first)
            let thumb = try? ImageSourceReader.preview(first, maxLongEdge: 160)
            await MainActor.run {
                self.firstInfo = info
                self.thumbnail = thumb
                self.scheduleEstimate()
            }
        }
    }

    func scheduleEstimate() {
        estimator.schedule(estimateKey)
    }

    /// Everything needed to plan the save, as plain values so planning can run off the main
    /// thread. Carries the estimate when it was made for exactly these settings.
    func planInputs() -> SavePlan {
        SavePlan(files: files, mode: naming.mode, singleName: naming.singleName(suggested: suggestions.best?.title),
                 recipes: Array(repeating: recipe, count: files.count), settings: options.settings,
                 suffix: preferences.sizeSuffix, reusable: isBatch ? nil : estimator.reusable(for: estimateKey))
    }

    /// Choices to remember for next time.
    func updatedPreferences() -> ExportPreferences {
        var updated = SettingsStore.shared.preferences
        options.store(into: &updated)
        updated.quickSaveWatermarkID = watermarkID
        return updated
    }
}

/// Sendable snapshot of the choices for planning a save, shared by the panel and the editor.
struct SavePlan: Sendable {
    let files: [URL]
    let mode: BatchNameMode
    let singleName: String?
    let recipes: [EditRecipe]
    let settings: ExportSettings
    let suffix: SizeSuffix
    let reusable: RenderedOutput?

    func makeJobs() -> [ExportJob] {
        ExportPlanner.makeJobs(sources: files, mode: mode, singleName: singleName, recipes: recipes,
                               settings: settings, namer: OutputFileNamer(suffix: suffix))
    }

    /// Rebuilds failed jobs for a folder the user picked after a permission error.
    var retry: ExportRunner.RetryPlanner {
        { [mode, singleName, suffix] failed, folder in
            ExportPlanner.retarget(failed, mode: mode, singleName: singleName, namer: OutputFileNamer(suffix: suffix), directory: folder)
        }
    }
}
