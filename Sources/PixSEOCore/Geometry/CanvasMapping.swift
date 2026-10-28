import CoreGraphics

/// Where an image is drawn when fitted into a view, and conversion between view points and
/// normalized image coordinates (0…1, top-left origin). Rotation and flip are already applied to
/// the preview the canvas shows, so no rotation happens here.
public struct CanvasMapping: Sendable, Equatable {
    /// The image's frame inside the view, in view points.
    public let imageFrame: CGRect

    public init(imageSize: CGSize, viewSize: CGSize, inset: CGFloat = 0) {
        let available = CGSize(width: max(viewSize.width - inset * 2, 1), height: max(viewSize.height - inset * 2, 1))
        let scale = min(available.width / max(imageSize.width, 1), available.height / max(imageSize.height, 1))
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        imageFrame = CGRect(x: (viewSize.width - size.width) / 2, y: (viewSize.height - size.height) / 2,
                            width: size.width, height: size.height)
    }

    public func viewPoint(_ unit: CGPoint) -> CGPoint {
        CGPoint(x: imageFrame.minX + unit.x * imageFrame.width, y: imageFrame.minY + unit.y * imageFrame.height)
    }

    public func unitPoint(_ view: CGPoint) -> CGPoint {
        CGPoint(x: (view.x - imageFrame.minX) / imageFrame.width, y: (view.y - imageFrame.minY) / imageFrame.height)
    }

    public func viewRect(_ unit: CGRect) -> CGRect {
        CGRect(origin: viewPoint(unit.origin), size: CGSize(width: unit.width * imageFrame.width, height: unit.height * imageFrame.height))
    }

    /// A view-space distance as a normalized vector.
    public func unitVector(_ view: CGSize) -> CGVector {
        CGVector(dx: view.width / imageFrame.width, dy: view.height / imageFrame.height)
    }
}
