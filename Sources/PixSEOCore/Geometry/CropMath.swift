import CoreGraphics

/// One of the eight handles on the crop frame.
public enum CropHandle: CaseIterable, Sendable {
    case topLeft, top, topRight, right, bottomRight, bottom, bottomLeft, left

    /// −1 moves the left edge, +1 the right edge, 0 neither.
    var horizontal: Int {
        switch self {
        case .topLeft, .left, .bottomLeft: -1
        case .topRight, .right, .bottomRight: 1
        case .top, .bottom: 0
        }
    }

    /// −1 moves the top edge, +1 the bottom edge, 0 neither.
    var vertical: Int {
        switch self {
        case .topLeft, .top, .topRight: -1
        case .bottomLeft, .bottom, .bottomRight: 1
        case .left, .right: 0
        }
    }
}

/// Crop rectangle editing. Rectangles are normalized (0…1, top-left origin) like `CropSpec.rect`;
/// the math runs in pixels of `size` (the rotated image) so ratios and minimum sizes are exact.
public enum CropMath {
    /// Smallest crop side, in real pixels.
    public static let minimumPixels: Double = 16

    /// Largest rectangle with `aspect` (width ÷ height) that fits the image, centered as close to
    /// `center` (normalized) as the image edges allow.
    public static func largestRect(aspect: Double, in size: PixelSize, centeredOn center: CGPoint = CGPoint(x: 0.5, y: 0.5)) -> CGRect {
        let (W, H) = (Double(size.width), Double(size.height))
        var w = W
        var h = W / aspect
        if h > H { h = H; w = H * aspect }
        let x = clamp(center.x * W - w / 2, 0, W - w)
        let y = clamp(center.y * H - h / 2, 0, H - h)
        return unit(CGRect(x: x, y: y, width: w, height: h), size)
    }

    /// Moves the rectangle without resizing it, stopping at the image edges.
    public static func moved(_ rect: CGRect, by delta: CGVector) -> CGRect {
        CGRect(x: clamp(rect.minX + delta.dx, 0, 1 - rect.width), y: clamp(rect.minY + delta.dy, 0, 1 - rect.height),
               width: rect.width, height: rect.height)
    }

    /// Drags `handle` to `point` (normalized). The opposite corner or edge stays put; with an
    /// `aspect` the ratio is kept exactly and edge handles grow the frame around its center line.
    public static func dragged(_ rect: CGRect, handle: CropHandle, to point: CGPoint, aspect: Double?, in size: PixelSize) -> CGRect {
        let (W, H) = (Double(size.width), Double(size.height))
        let r = pixels(rect, size)
        let p = CGPoint(x: clamp(point.x * W, 0, W), y: clamp(point.y * H, 0, H))
        let (minW, minH) = (min(minimumPixels, W), min(minimumPixels, H))
        let (dx, dy) = (handle.horizontal, handle.vertical)

        var left = r.minX, right = r.maxX, top = r.minY, bottom = r.maxY
        if dx < 0 { left = min(p.x, right - minW) } else if dx > 0 { right = max(p.x, left + minW) }
        if dy < 0 { top = min(p.y, bottom - minH) } else if dy > 0 { bottom = max(p.y, top + minH) }
        guard let aspect else {
            return unit(CGRect(x: left, y: top, width: right - left, height: bottom - top), size)
        }

        var w = right - left
        var h = bottom - top
        // Room from the fixed side(s) to the image edge in the dragging direction.
        var roomW = dx < 0 ? r.maxX : dx > 0 ? W - r.minX : W
        var roomH = dy < 0 ? r.maxY : dy > 0 ? H - r.minY : H
        if dx != 0, dy != 0 {
            // Corner: follow whichever side the pointer pulled further.
            if w / h > aspect { h = w / aspect } else { w = h * aspect }
        } else if dx != 0 {
            h = w / aspect
            roomH = H
        } else {
            w = h * aspect
            roomW = W
        }
        let grow = max(1, minW / w, minH / h)
        w *= grow; h *= grow
        let shrink = min(1, roomW / w, roomH / h)
        w *= shrink; h *= shrink

        let x = dx < 0 ? r.maxX - w : dx > 0 ? r.minX : clamp(r.midX - w / 2, 0, W - w)
        let y = dy < 0 ? r.maxY - h : dy > 0 ? r.minY : clamp(r.midY - h / 2, 0, H - h)
        return unit(CGRect(x: x, y: y, width: w, height: h), size)
    }

    static func pixels(_ r: CGRect, _ s: PixelSize) -> CGRect {
        CGRect(x: r.minX * Double(s.width), y: r.minY * Double(s.height), width: r.width * Double(s.width), height: r.height * Double(s.height))
    }

    static func unit(_ r: CGRect, _ s: PixelSize) -> CGRect {
        CGRect(x: r.minX / Double(s.width), y: r.minY / Double(s.height), width: r.width / Double(s.width), height: r.height / Double(s.height))
    }

    static func clamp(_ value: Double, _ low: Double, _ high: Double) -> Double {
        min(max(value, low), max(low, high))
    }
}

extension CropSpec {
    /// Turns the picture the user sees a quarter clockwise; the crop frame turns with it.
    /// After a flip, a visual clockwise turn is one turn less on the stored (pre-flip) rotation.
    public func rotatedClockwise() -> CropSpec {
        CropSpec(rect: CGRect(x: 1 - rect.maxY, y: rect.minX, width: rect.height, height: rect.width),
                 quarterTurns: quarterTurns + (flipHorizontal ? -1 : 1), flipHorizontal: flipHorizontal)
    }

    public func rotatedCounterclockwise() -> CropSpec {
        rotatedClockwise().rotatedClockwise().rotatedClockwise()
    }

    /// Mirrors the picture the user sees; the crop frame is mirrored too.
    public func flippedHorizontally() -> CropSpec {
        CropSpec(rect: CGRect(x: 1 - rect.maxX, y: rect.minY, width: rect.width, height: rect.height),
                 quarterTurns: quarterTurns, flipHorizontal: !flipHorizontal)
    }

    /// True when nothing is cropped, turned or flipped.
    public var isIdentity: Bool {
        quarterTurns == 0 && !flipHorizontal && rect == CGRect(x: 0, y: 0, width: 1, height: 1)
    }
}
