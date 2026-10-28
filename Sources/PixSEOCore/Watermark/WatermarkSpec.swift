import CoreGraphics
import Foundation

/// sRGB color with alpha, 0…1.
public struct RGBAColor: Codable, Sendable, Hashable {
    public var red: Double, green: Double, blue: Double, alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        (self.red, self.green, self.blue, self.alpha) = (red, green, blue, alpha)
    }

    public static let white = RGBAColor(red: 1, green: 1, blue: 1)
    public static let black = RGBAColor(red: 0, green: 0, blue: 0)

    public var cgColor: CGColor { CGColor(srgbRed: red, green: green, blue: blue, alpha: alpha) }

    /// WCAG relative luminance.
    public var luminance: Double {
        func linear(_ c: Double) -> Double { c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }
}

/// One of nine places a watermark snaps to.
public enum WatermarkAnchor: String, Codable, Sendable, CaseIterable {
    case topLeft, top, topRight, left, center, right, bottomLeft, bottom, bottomRight

    /// 0, 0.5 or 1 along each axis.
    public var unit: CGPoint {
        let x: Double = [.topLeft, .left, .bottomLeft].contains(self) ? 0 : [.top, .center, .bottom].contains(self) ? 0.5 : 1
        let y: Double = [.topLeft, .top, .topRight].contains(self) ? 0 : [.left, .center, .right].contains(self) ? 0.5 : 1
        return CGPoint(x: x, y: y)
    }

    public static let corners: [WatermarkAnchor] = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

/// How text stays readable on busy backgrounds.
public enum WatermarkLegibility: String, Codable, Sendable, CaseIterable {
    case auto, outline, shadow, none
}

/// A text or logo watermark. Every measure is a fraction of the output image, so the mark looks
/// the same at any export size and on every image of a batch.
public struct WatermarkSpec: Codable, Sendable, Hashable {
    public enum Kind: Codable, Sendable, Hashable {
        case text(String)
        /// Absolute path of a logo copied into Application Support, so deleting the original is safe.
        case logo(path: String)
    }

    public var kind: Kind
    /// Font family name; the regular (or bold) face of the family is used.
    public var fontName: String
    public var bold: Bool
    public var color: RGBAColor
    public var legibility: WatermarkLegibility
    /// Watermark width ÷ output width, 0.03…0.6.
    public var widthFraction: Double
    public var opacity: Double
    /// −45…45, positive turns counterclockwise.
    public var rotationDegrees: Double
    public var anchor: WatermarkAnchor
    /// Nudge from the anchor position, as a fraction of the output width and height.
    public var offset: CGVector
    /// Pick the emptiest corner of each image instead of `anchor`.
    public var autoCorner: Bool
    /// Margin from the edges, as a fraction of the short edge.
    public var marginFraction: Double

    public init(kind: Kind = .text("© "), fontName: String = "Helvetica Neue", bold: Bool = true,
                color: RGBAColor = .white, legibility: WatermarkLegibility = .auto, widthFraction: Double = 0.18,
                opacity: Double = 0.85, rotationDegrees: Double = 0, anchor: WatermarkAnchor = .bottomRight,
                offset: CGVector = .zero, autoCorner: Bool = false, marginFraction: Double = 0.03) {
        self.kind = kind
        self.fontName = fontName
        self.bold = bold
        self.color = color
        self.legibility = legibility
        self.widthFraction = min(max(widthFraction, 0.03), 0.6)
        self.opacity = min(max(opacity, 0), 1)
        self.rotationDegrees = min(max(rotationDegrees, -45), 45)
        self.anchor = anchor
        self.offset = offset
        self.autoCorner = autoCorner
        self.marginFraction = marginFraction
    }

    /// True when there's nothing to draw (empty text).
    public var isEmpty: Bool {
        if case .text(let text) = kind { return text.trimmingCharacters(in: .whitespaces).isEmpty }
        return false
    }
}

/// Where the watermark goes, in pixels with a top-left origin. Pure math shared by the renderer
/// and the editor's drag overlay.
public enum WatermarkLayout {
    /// - Parameter markAspect: mark height ÷ width.
    public static func frame(markAspect: Double, canvas: PixelSize, spec: WatermarkSpec, anchor: WatermarkAnchor? = nil) -> CGRect {
        let (W, H) = (Double(canvas.width), Double(canvas.height))
        let w = (spec.widthFraction * W).rounded()
        let h = max(1, (w * markAspect).rounded())
        let margin = spec.marginFraction * Double(min(canvas.width, canvas.height))
        let unit = (anchor ?? spec.anchor).unit
        let x = margin + unit.x * (W - w - 2 * margin) + spec.offset.dx * W
        let y = margin + unit.y * (H - h - 2 * margin) + spec.offset.dy * H
        return CGRect(x: min(max(x, 0), max(0, W - w)), y: min(max(y, 0), max(0, H - h)), width: w, height: h)
    }

    /// The anchor nearest to where a dragged mark's center ended up, and the offset that keeps
    /// it there. Offsets within `snap` (a fraction of the width) of the anchor become zero.
    public static func anchorAndOffset(forOrigin origin: CGPoint, markAspect: Double, canvas: PixelSize,
                                       spec: WatermarkSpec, snap: Double = 0.012) -> (WatermarkAnchor, CGVector) {
        var base = spec
        base.offset = .zero
        let size = frame(markAspect: markAspect, canvas: canvas, spec: base).size
        let center = CGPoint(x: (origin.x + size.width / 2) / Double(canvas.width), y: (origin.y + size.height / 2) / Double(canvas.height))
        let column = center.x < 1.0 / 3 ? 0 : center.x < 2.0 / 3 ? 1 : 2
        let row = center.y < 1.0 / 3 ? 0 : center.y < 2.0 / 3 ? 1 : 2
        let anchor = WatermarkAnchor.allCases[row * 3 + column]
        let home = frame(markAspect: markAspect, canvas: canvas, spec: base, anchor: anchor).origin
        var offset = CGVector(dx: (origin.x - home.x) / Double(canvas.width), dy: (origin.y - home.y) / Double(canvas.height))
        if abs(offset.dx) < snap, abs(offset.dy) < snap { offset = .zero }
        return (anchor, offset)
    }
}
