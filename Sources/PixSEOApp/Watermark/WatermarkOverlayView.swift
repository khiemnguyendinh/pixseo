import PixSEOCore
import SwiftUI

/// The final preview (crop + watermark) with a draggable box over the watermark: drag to move
/// (snaps to the nine positions), drag the corner to resize, ⌫ to remove.
struct WatermarkOverlayView: View {
    @Bindable var model: EditorViewModel
    let image: CGImage
    @State private var dragStart: WatermarkSpec?
    @FocusState private var focused: Bool

    var body: some View {
        GeometryReader { proxy in
            let canvas = PixelSize(width: image.width, height: image.height)
            let mapping = CanvasMapping(imageSize: CGSize(width: image.width, height: image.height), viewSize: proxy.size, inset: 24)
            ZStack(alignment: .topLeading) {
                Image(decorative: image, scale: 1).resizable()
                    .frame(width: mapping.imageFrame.width, height: mapping.imageFrame.height)
                    .offset(x: mapping.imageFrame.minX, y: mapping.imageFrame.minY)
                if model.watermarkEnabled, !model.watermark.autoCorner, let aspect = WatermarkRenderer.markAspect(model.watermark) {
                    let px = WatermarkLayout.frame(markAspect: aspect, canvas: canvas, spec: model.watermark)
                    let unit = CGRect(x: px.minX / Double(canvas.width), y: px.minY / Double(canvas.height),
                                      width: px.width / Double(canvas.width), height: px.height / Double(canvas.height))
                    let box = mapping.viewRect(unit)
                    Rectangle().stroke(Color.accentColor, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        .contentShape(Rectangle())
                        .frame(width: box.width, height: box.height)
                        .position(x: box.midX, y: box.midY)
                        .gesture(moveGesture(aspect: aspect, canvas: canvas, mapping: mapping))
                    Circle().fill(Color.accentColor).frame(width: 10, height: 10)
                        .position(x: box.maxX, y: box.maxY)
                        .gesture(scaleGesture(canvas: canvas, mapping: mapping))
                }
            }
        }
        .focusable()
        .focused($focused)
        .focusEffectDisabled()
        .onKeyPress(keys: [.delete, .deleteForward]) { _ in
            model.watermarkEnabled = false
            return .handled
        }
        .onTapGesture { focused = true }
    }

    /// Pixels of the preview per view point.
    private func scale(_ canvas: PixelSize, _ mapping: CanvasMapping) -> Double {
        Double(canvas.width) / mapping.imageFrame.width
    }

    private func moveGesture(aspect: Double, canvas: PixelSize, mapping: CanvasMapping) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                let start = dragStart ?? model.watermark
                dragStart = start
                let origin = WatermarkLayout.frame(markAspect: aspect, canvas: canvas, spec: start).origin
                let s = scale(canvas, mapping)
                let moved = CGPoint(x: origin.x + value.translation.width * s, y: origin.y + value.translation.height * s)
                let (anchor, offset) = WatermarkLayout.anchorAndOffset(forOrigin: moved, markAspect: aspect, canvas: canvas, spec: start)
                model.watermark.anchor = anchor
                model.watermark.offset = offset
            }
            .onEnded { _ in dragStart = nil }
    }

    private func scaleGesture(canvas: PixelSize, mapping: CanvasMapping) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let start = dragStart ?? model.watermark
                dragStart = start
                let width = start.widthFraction * Double(canvas.width) + value.translation.width * scale(canvas, mapping)
                model.watermark.widthFraction = min(max(width / Double(canvas.width), 0.03), 0.6)
            }
            .onEnded { _ in dragStart = nil }
    }
}
