import CoreGraphics
import Foundation
import Observation
import PixSEOCore

enum EditorTab: Int, CaseIterable {
    case resize, crop, watermark

    var title: String {
        switch self {
        case .resize: "Resize"
        case .crop: "Crop"
        case .watermark: "Watermark"
        }
    }
}

/// Crop of one image in the batch. `placed` = the frame was fitted to the current ratio;
/// `manual` = the user adjusted it (shown as a dot on the filmstrip).
struct ImageEdit: Equatable, Sendable {
    var crop = CropSpec()
    var placed = false
    var manual = false
}

/// State of an editor window: images, per-image crops, the shared watermark and export choices.
/// Preview rendering lives in `EditorViewModel+Preview`, save planning in `EditorViewModel+Save`.
@MainActor
@Observable
final class EditorViewModel {
    let files: [URL]
    var index = 0 { didSet { if index != oldValue { loadCurrent() } } }
    var tab: EditorTab

    let options: ExportOptions
    let naming: FileNaming
    let suggestions = SuggestionModel()
    let estimator: SizeEstimator
    let sizeSuffix: SizeSuffix

    // Crop: one ratio for the batch, one frame per image.
    var aspect: AspectRatioPreset = .free { didSet { if aspect != oldValue { ratioChanged() } } }
    var aspectSwapped = false { didSet { if aspectSwapped != oldValue { ratioChanged() } } }
    var edits: [URL: ImageEdit] = [:]

    // Watermark, shared by the batch.
    var watermarkEnabled: Bool { didSet { changed() } }
    var watermark: WatermarkSpec { didSet { if watermark != oldValue { changed() } } }

    /// Unsaved edits; closing asks first.
    private(set) var hasChanges = false

    // Current image previews (see +Preview).
    var info: SourceImageInfo?
    var basePreview: CGImage?
    var orientedPreview: CGImage?
    var finalPreview: CGImage?
    var previewCache: [URL: (CGImage, SourceImageInfo)] = [:]
    var boxesCache: [String: SubjectBoxes] = [:]
    var finalTask: Task<Void, Never>?
    var orientTask: Task<Void, Never>?

    init(files: [URL], tab: EditorTab, options: ExportOptions, naming: FileNaming? = nil,
         watermark: WatermarkSpec?, service: ExportService) {
        self.files = files
        self.tab = tab
        self.options = options
        self.naming = naming ?? FileNaming(files: files)
        estimator = SizeEstimator(service: service)
        let preferences = SettingsStore.shared.preferences
        sizeSuffix = preferences.sizeSuffix
        let start = watermark ?? SettingsStore.shared.watermarkPresets.defaultPreset?.spec ?? preferences.lastWatermark
        self.watermark = start ?? WatermarkSpec(kind: .text("© "))
        watermarkEnabled = watermark != nil || tab == .watermark
    }

    var current: URL { files[index] }
    var isBatch: Bool { files.count > 1 }

    var currentEdit: ImageEdit {
        get { edits[current] ?? ImageEdit() }
        set { edits[current] = newValue }
    }

    /// Size of the current image after its rotation, which crop ratios are measured in.
    var rotatedSize: PixelSize? {
        info.map { currentEdit.crop.quarterTurns % 2 == 1 ? $0.pixelSize.transposed : $0.pixelSize }
    }

    /// Width ÷ height the crop must keep, or `nil` for a free crop.
    func ratio(for size: PixelSize) -> Double? {
        guard let base = aspect.ratio(original: size) else { return nil }
        return aspectSwapped && aspect.canSwapOrientation ? 1 / base : base
    }

    var activeWatermark: WatermarkSpec? { watermarkEnabled && !watermark.isEmpty ? watermark : nil }

    func recipe(crop: CropSpec) -> EditRecipe {
        let fixed = aspect == .openGraph ? PixelSize(width: 1200, height: 630) : nil
        return EditRecipe(crop: crop.isIdentity ? nil : crop, resize: options.resize(fixedSize: fixed),
                          sharpen: options.sharpen, watermark: activeWatermark)
    }

    var currentRecipe: EditRecipe { recipe(crop: currentEdit.crop) }

    var outputSize: PixelSize? {
        guard let info else { return nil }
        let cropped = OutputGeometry.croppedSize(source: info.pixelSize, crop: currentRecipe.crop)
        return OutputGeometry.outputSize(for: cropped, resize: currentRecipe.resize).size
    }

    var estimateKey: ExportJob { SizeEstimator.key(source: current, recipe: currentRecipe, settings: options.settings) }

    var namer: OutputFileNamer { OutputFileNamer(suffix: sizeSuffix) }

    var previewFileName: String {
        naming.preview(outputSize: outputSize, format: options.format, namer: namer, suggested: suggestions.best?.title)
    }

    var advice: [ExportAdvisor.Advice] {
        if case .dimensionTooLarge(let max) = estimator.error { return [.dimensionTooLarge(max: max)] }
        return ExportAdvisor.advice(info: info, format: options.format, width: options.width,
                                    estimateWarnings: estimator.warnings(for: estimateKey))
    }

    var checklist: SEOChecklist? {
        guard !isBatch else { return nil }
        let slug = SEOSlugger.slugify(naming.singleName(suggested: suggestions.best?.title) ?? current.deletingPathExtension().lastPathComponent)
        return SEOChecklist(bytes: estimator.reusable(for: estimateKey)?.data.count, outputSize: outputSize, slug: slug,
                            format: options.format, contentKind: info?.contentKind, frameCount: info?.frameCount ?? 1,
                            hasAltText: !suggestions.altText.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    func start() {
        suggestions.start(file: files[0], isBatch: isBatch, sourceIsMeaningless: naming.sourceIsMeaningless)
        loadCurrent()
    }

    func next() { if index + 1 < files.count { index += 1 } }
    func previous() { if index > 0 { index -= 1 } }

    // MARK: Crop actions

    /// From the overlay: the user moved or resized the frame.
    func setCropRect(_ rect: CGRect) {
        var edit = currentEdit
        edit.crop.rect = rect
        edit.manual = true
        edit.placed = true
        currentEdit = edit
        changed()
    }

    func rotate(clockwise: Bool) {
        var edit = currentEdit
        edit.crop = clockwise ? edit.crop.rotatedClockwise() : edit.crop.rotatedCounterclockwise()
        // A locked ratio is fitted again to the turned picture.
        if aspect != .free { edit.placed = false }
        currentEdit = edit
        changed()
        refreshOriented()
    }

    func flip() {
        var edit = currentEdit
        edit.crop = edit.crop.flippedHorizontally()
        currentEdit = edit
        changed()
        refreshOriented()
    }

    /// Clears crop, rotation and flip of the current image.
    func resetCrop() {
        currentEdit = ImageEdit()
        changed()
        refreshOriented()
    }

    /// Fits the frame to the subject again, discarding manual changes on this image.
    func placeOnSubject() {
        var edit = currentEdit
        edit.placed = false
        edit.manual = false
        currentEdit = edit
        placeIfNeeded()
    }

    private func ratioChanged() {
        // Every image is fitted again, each around its own subject.
        for (url, edit) in edits { edits[url] = ImageEdit(crop: CropSpec(quarterTurns: edit.crop.quarterTurns, flipHorizontal: edit.crop.flipHorizontal)) }
        if aspect.fixedWidth != nil { options.widthChoice = ExportOptions.customWidthTag; options.customWidthText = "1200" }
        changed()
        placeIfNeeded()
    }

    func changed() {
        hasChanges = true
        refreshFinal()
        estimator.schedule(estimateKey)
    }

    func markSaved() {
        hasChanges = false
    }
}
