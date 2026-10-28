import CoreGraphics
import Foundation
import PixSEOCore

/// Turning the editor's state into export jobs.
extension EditorViewModel {
    var canSave: Bool { naming.isComplete && info != nil }

    /// Builds the save plan. Images the user never opened still get their crop fitted around
    /// their own subject, which needs Vision, so this runs in the background.
    func makePlan() async -> SavePlan {
        let ratioFor: @Sendable (PixelSize) -> Double? = { [aspect, aspectSwapped] size in
            guard let base = aspect.ratio(original: size) else { return nil }
            return aspectSwapped && aspect.canSwapOrientation ? 1 / base : base
        }
        let pending = files.map { (url: $0, edit: edits[$0] ?? ImageEdit()) }
        let crops = await Task.detached(priority: .userInitiated) {
            pending.map { item -> CropSpec in
                item.edit.placed ? item.edit.crop : Self.autoCrop(item.url, edit: item.edit, ratioFor: ratioFor)
            }
        }.value
        let reusable = isBatch ? nil : estimator.reusable(for: estimateKey)
        return SavePlan(files: files, mode: naming.mode, singleName: naming.singleName(suggested: suggestions.best?.title),
                        recipes: crops.map(recipe(crop:)), settings: options.settings, suffix: sizeSuffix, reusable: reusable)
    }

    /// Crop for an image that was never shown: the ratio fitted around its subject, keeping any
    /// rotation. A free ratio leaves it uncropped.
    nonisolated static func autoCrop(_ url: URL, edit: ImageEdit, ratioFor: (PixelSize) -> Double?) -> CropSpec {
        guard let info = try? ImageSourceReader.readInfo(url) else { return edit.crop }
        let size = edit.crop.quarterTurns % 2 == 1 ? info.pixelSize.transposed : info.pixelSize
        guard let ratio = ratioFor(size) else { return edit.crop }
        let oriented = (try? ImageSourceReader.preview(url, maxLongEdge: 1024)).flatMap {
            render($0, crop: CropSpec(quarterTurns: edit.crop.quarterTurns, flipHorizontal: edit.crop.flipHorizontal),
                   watermark: nil, maxEdge: 1024)
        }
        let boxes = oriented.map(SaliencyAnalyzer.analyze) ?? SubjectBoxes()
        var crop = edit.crop
        crop.rect = SmartCropPlacement.place(aspect: ratio, in: size, boxes: boxes)
        return crop
    }

    /// Remembers export choices and the watermark for next time.
    func storePreferences() {
        var preferences = SettingsStore.shared.preferences
        options.store(into: &preferences)
        if watermarkEnabled, !watermark.isEmpty { preferences.lastWatermark = watermark }
        SettingsStore.shared.preferences = preferences
    }
}
