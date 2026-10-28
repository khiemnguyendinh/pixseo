import PixSEOCore
import SwiftUI

/// The turned/flipped picture with a draggable crop frame: darkened outside, eight handles,
/// rule-of-thirds lines while dragging, and the real pixel size of the crop.
/// Drags update only local state; the model is updated when the drag ends.
struct CropOverlayView: View {
    let model: EditorViewModel
    let image: CGImage
    @State private var liveRect: CGRect?
    @State private var dragStart: CGRect?
    @FocusState private var focused: Bool

    private var rect: CGRect { liveRect ?? model.currentEdit.crop.rect }

    var body: some View {
        GeometryReader { proxy in
            let mapping = CanvasMapping(imageSize: CGSize(width: image.width, height: image.height), viewSize: proxy.size, inset: 24)
            let frame = mapping.viewRect(rect)
            ZStack(alignment: .topLeading) {
                Image(decorative: image, scale: 1).resizable()
                    .frame(width: mapping.imageFrame.width, height: mapping.imageFrame.height)
                    .offset(x: mapping.imageFrame.minX, y: mapping.imageFrame.minY)
                Path { path in
                    path.addRect(mapping.imageFrame)
                    path.addRect(frame)
                }
                .fill(Color.black.opacity(0.55), style: FillStyle(eoFill: true))
                .allowsHitTesting(false)
                frameView(frame)
                    .contentShape(Rectangle())
                    .gesture(moveGesture(mapping))
                ForEach(CropHandle.allCases, id: \.self) { handle in
                    Rectangle().fill(.white).frame(width: 10, height: 10)
                        .overlay(Rectangle().stroke(.black.opacity(0.4)))
                        .position(position(of: handle, in: frame))
                        .gesture(resizeGesture(handle, mapping))
                }
                sizeLabel.position(x: frame.maxX - 50, y: frame.maxY + 14)
            }
        }
        .focusable()
        .focused($focused)
        .focusEffectDisabled()
        .onKeyPress(keys: [.leftArrow, .rightArrow, .upArrow, .downArrow]) { press in
            nudge(press.key, step: press.modifiers.contains(.shift) ? 10 : 1)
            return .handled
        }
        .onTapGesture { focused = true }
    }

    private func frameView(_ frame: CGRect) -> some View {
        ZStack {
            Rectangle().stroke(.white, lineWidth: 1.5)
            if dragStart != nil {
                Path { path in
                    for i in 1...2 {
                        let x = frame.width * CGFloat(i) / 3, y = frame.height * CGFloat(i) / 3
                        path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: frame.height))
                        path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: frame.width, y: y))
                    }
                }
                .stroke(.white.opacity(0.6), lineWidth: 0.5)
            }
        }
        .frame(width: frame.width, height: frame.height)
        .position(x: frame.midX, y: frame.midY)
    }

    private var sizeLabel: some View {
        let size = model.rotatedSize.map { s in
            PixelSize(width: Int((rect.width * Double(s.width)).rounded()), height: Int((rect.height * Double(s.height)).rounded()))
        }
        return Text(size?.description ?? "").font(.caption.monospacedDigit()).padding(.horizontal, 6).padding(.vertical, 2)
            .background(.black.opacity(0.6), in: Capsule()).foregroundStyle(.white)
    }

    private func moveGesture(_ mapping: CanvasMapping) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                let start = dragStart ?? rect
                dragStart = start
                liveRect = CropMath.moved(start, by: mapping.unitVector(value.translation))
            }
            .onEnded { _ in commit() }
    }

    private func resizeGesture(_ handle: CropHandle, _ mapping: CanvasMapping) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                guard let size = model.rotatedSize else { return }
                let start = dragStart ?? rect
                dragStart = start
                let origin = position(of: handle, in: mapping.viewRect(start))
                let point = mapping.unitPoint(CGPoint(x: origin.x + value.translation.width, y: origin.y + value.translation.height))
                liveRect = CropMath.dragged(start, handle: handle, to: point, aspect: model.ratio(for: size), in: size)
            }
            .onEnded { _ in commit() }
    }

    private func commit() {
        if let liveRect { model.setCropRect(liveRect) }
        liveRect = nil
        dragStart = nil
    }

    /// Arrow keys move the frame by one preview pixel (⇧: ten).
    private func nudge(_ key: KeyEquivalent, step: Double) {
        let (dx, dy) = (step / Double(image.width), step / Double(image.height))
        let delta: CGVector = switch key {
        case .leftArrow: CGVector(dx: -dx, dy: 0)
        case .rightArrow: CGVector(dx: dx, dy: 0)
        case .upArrow: CGVector(dx: 0, dy: -dy)
        default: CGVector(dx: 0, dy: dy)
        }
        model.setCropRect(CropMath.moved(rect, by: delta))
    }

    private func position(of handle: CropHandle, in frame: CGRect) -> CGPoint {
        let x: CGFloat = [.topLeft, .left, .bottomLeft].contains(handle) ? frame.minX : [.top, .bottom].contains(handle) ? frame.midX : frame.maxX
        let y: CGFloat = [.topLeft, .top, .topRight].contains(handle) ? frame.minY : [.left, .right].contains(handle) ? frame.midY : frame.maxY
        return CGPoint(x: x, y: y)
    }
}
