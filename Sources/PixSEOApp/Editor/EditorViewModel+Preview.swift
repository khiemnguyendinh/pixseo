import CoreGraphics
import Foundation
import PixSEOCore

/// Preview images for the canvas. Everything is rendered from one decoded preview (≤ 2048 px)
/// with the same pipeline as the export, so the canvas shows what will be saved.
extension EditorViewModel {
    nonisolated static let previewEdge = 2048
    /// The final preview (crop + watermark) is smaller so dragging the watermark stays smooth.
    nonisolated static let finalPreviewEdge = 1400

    /// Decodes the current image (cached for a few images) and refreshes every preview.
    func loadCurrent() {
        let url = current
        if let (image, info) = previewCache[url] {
            show(image, info: info)
            return
        }
        basePreview = nil
        orientedPreview = nil
        finalPreview = nil
        Task {
            let loaded = await Task.detached(priority: .userInitiated) { () -> (CGImage, SourceImageInfo)? in
                try? ImageSourceReader.ensureDownloaded(url)
                guard let info = try? ImageSourceReader.readInfo(url),
                      let image = try? ImageSourceReader.preview(url, maxLongEdge: Self.previewEdge) else { return nil }
                return (image, info)
            }.value
            guard let loaded, url == current else { return }
            if previewCache.count >= 4 { previewCache.removeAll() }
            previewCache[url] = loaded
            show(loaded.0, info: loaded.1)
        }
    }

    private func show(_ image: CGImage, info: SourceImageInfo) {
        basePreview = image
        self.info = info
        refreshOriented()
        estimator.schedule(estimateKey)
    }

    /// Re-renders the turned/flipped (uncropped) picture the crop tab shows, then fits the frame.
    func refreshOriented() {
        guard let base = basePreview else { return }
        let spec = CropSpec(quarterTurns: currentEdit.crop.quarterTurns, flipHorizontal: currentEdit.crop.flipHorizontal)
        orientTask?.cancel()
        orientTask = Task {
            let image = await Task.detached(priority: .userInitiated) {
                Self.render(base, crop: spec, watermark: nil, maxEdge: Self.previewEdge)
            }.value
            guard !Task.isCancelled else { return }
            orientedPreview = image
            placeIfNeeded()
            refreshFinal()
        }
    }

    /// Fits the crop frame to the ratio around the subject, once per image and ratio.
    func placeIfNeeded() {
        guard let oriented = orientedPreview, let size = rotatedSize, let ratio = ratio(for: size), !currentEdit.placed else { return }
        let url = current
        let edit = currentEdit
        let key = "\(url.path)|\(edit.crop.quarterTurns)|\(edit.crop.flipHorizontal)"
        Task {
            let boxes: SubjectBoxes
            if let cached = boxesCache[key] {
                boxes = cached
            } else {
                boxes = await Task.detached(priority: .userInitiated) { SaliencyAnalyzer.analyze(oriented) }.value
                boxesCache[key] = boxes
            }
            guard url == current, !currentEdit.placed else { return }
            var placed = currentEdit
            placed.crop.rect = SmartCropPlacement.place(aspect: ratio, in: size, boxes: boxes)
            placed.placed = true
            currentEdit = placed
            refreshFinal()
            estimator.schedule(estimateKey)
        }
    }

    /// Re-renders crop + watermark ~30 ms after the last change.
    func refreshFinal() {
        guard let base = basePreview else { return }
        let crop = currentEdit.crop
        let watermark = activeWatermark
        finalTask?.cancel()
        finalTask = Task {
            try? await Task.sleep(for: .milliseconds(30))
            guard !Task.isCancelled else { return }
            let image = await Task.detached(priority: .userInitiated) {
                Self.render(base, crop: crop, watermark: watermark, maxEdge: Self.finalPreviewEdge)
            }.value
            guard !Task.isCancelled else { return }
            finalPreview = image
        }
    }

    /// Crop/turn/flip and watermark at preview scale, no sharpening.
    nonisolated static func render(_ base: CGImage, crop: CropSpec, watermark: WatermarkSpec?, maxEdge: Int) -> CGImage? {
        let source = PixelSize(width: base.width, height: base.height)
        let cropped = OutputGeometry.croppedSize(source: source, crop: crop)
        let size = OutputGeometry.outputSize(for: cropped, resize: ResizeSpec(mode: .longEdge, value: maxEdge)).size
        let recipe = EditRecipe(crop: crop.isIdentity ? nil : crop, sharpen: false, watermark: watermark)
        return try? RenderPipeline.render(base, recipe: recipe, outputSize: size, flattenOnWhite: false)
    }
}
