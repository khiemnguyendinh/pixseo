import CoreGraphics
import CoreText
import Foundation

/// Draws a watermark onto a rendered image at its real output size, so text stays sharp.
/// The editor previews with the same renderer, so what the user sees is what gets saved.
public enum WatermarkRenderer {
    // NSCache is thread-safe; the annotation only tells Swift so.
    nonisolated(unsafe) private static let logoCache = NSCache<NSString, DecodedImage>()

    /// Mark height ÷ width, or `nil` when there's nothing drawable (unreadable logo).
    public static func markAspect(_ spec: WatermarkSpec) -> Double? {
        switch spec.kind {
        case .text(let text):
            let metrics = lineMetrics(text, font: font(spec, size: 100), spec: spec, stroke: nil)
            return metrics.width > 0 ? metrics.height / metrics.width : nil
        case .logo(let path):
            return logo(path).map { Double($0.height) / Double(max($0.width, 1)) }
        }
    }

    public static func apply(_ spec: WatermarkSpec, to image: CGImage) -> CGImage {
        guard !spec.isEmpty, let aspect = markAspect(spec) else { return image }
        let canvas = PixelSize(width: image.width, height: image.height)
        let anchor = spec.autoCorner ? WatermarkPlacementAdvisor.emptiestCorner(of: image) : spec.anchor
        let frame = WatermarkLayout.frame(markAspect: aspect, canvas: canvas, spec: spec, anchor: anchor)
        let bounds = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        guard let context = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return image }
        context.draw(image, in: bounds)

        // Core Graphics has a bottom-left origin; the layout is top-left.
        let target = CGRect(x: frame.minX, y: Double(image.height) - frame.maxY, width: frame.width, height: frame.height)
        context.saveGState()
        context.translateBy(x: target.midX, y: target.midY)
        context.rotate(by: spec.rotationDegrees * .pi / 180)
        context.translateBy(x: -target.midX, y: -target.midY)
        // A transparency layer applies opacity once to the whole mark (fill + outline together).
        context.setAlpha(spec.opacity)
        context.beginTransparencyLayer(auxiliaryInfo: nil)
        switch spec.kind {
        case .text(let text):
            let background = WatermarkPlacementAdvisor.averageLuminance(of: image, in: frame)
            drawText(text, spec: spec, in: target, context: context, backgroundLuminance: background)
        case .logo(let path):
            if let logo = logo(path) {
                context.interpolationQuality = .high
                context.draw(logo, in: target)
            }
        }
        context.endTransparencyLayer()
        context.restoreGState()
        return context.makeImage() ?? image
    }

    // MARK: Text

    private static func drawText(_ text: String, spec: WatermarkSpec, in target: CGRect, context: CGContext, backgroundLuminance: Double) {
        let probe = lineMetrics(text, font: font(spec, size: 100), spec: spec, stroke: nil)
        let size = 100 * target.width / max(probe.width, 1)
        let font = font(spec, size: size)

        var stroke: CGColor?
        var shadow = false
        switch spec.legibility {
        case .none: break
        case .outline: stroke = contrasting(spec.color)
        case .shadow: shadow = true
        case .auto:
            // WCAG: below 3:1 against the background, a thin contrasting outline keeps it readable.
            let (a, b) = (spec.color.luminance, backgroundLuminance)
            if (max(a, b) + 0.05) / (min(a, b) + 0.05) < 3 { stroke = contrasting(spec.color) }
        }
        if shadow {
            context.setShadow(offset: CGSize(width: 0, height: -size * 0.04), blur: size * 0.08,
                              color: CGColor(gray: spec.color.luminance > 0.5 ? 0 : 1, alpha: 0.6))
        }
        let metrics = lineMetrics(text, font: font, spec: spec, stroke: stroke)
        context.textPosition = CGPoint(x: target.minX, y: target.minY + metrics.descent)
        CTLineDraw(metrics.line, context)
    }

    private static func contrasting(_ color: RGBAColor) -> CGColor {
        color.luminance > 0.4 ? CGColor(gray: 0, alpha: 0.85) : CGColor(gray: 1, alpha: 0.85)
    }

    private struct LineMetrics {
        let line: CTLine
        let width: Double
        let height: Double
        let descent: Double
    }

    private static func lineMetrics(_ text: String, font: CTFont, spec: WatermarkSpec, stroke: CGColor?) -> LineMetrics {
        var attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): spec.color.cgColor,
        ]
        if let stroke {
            // Negative width = fill and stroke; 3% of the font size.
            attributes[NSAttributedString.Key(kCTStrokeWidthAttributeName as String)] = -3.0
            attributes[NSAttributedString.Key(kCTStrokeColorAttributeName as String)] = stroke
        }
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attributes))
        var ascent: CGFloat = 0, descent: CGFloat = 0, leading: CGFloat = 0
        let width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
        return LineMetrics(line: line, width: width, height: ascent + descent, descent: descent)
    }

    /// The family's regular face, or bold when asked; unknown families fall back to the system font.
    static func font(_ spec: WatermarkSpec, size: Double) -> CTFont {
        let descriptor = CTFontDescriptorCreateWithAttributes([kCTFontFamilyNameAttribute: spec.fontName] as CFDictionary)
        let base = CTFontCreateWithFontDescriptor(descriptor, size, nil)
        guard spec.bold else { return base }
        return CTFontCreateCopyWithSymbolicTraits(base, size, nil, .traitBold, .traitBold) ?? base
    }

    // MARK: Logo

    private static func logo(_ path: String) -> CGImage? {
        if let cached = logoCache.object(forKey: path as NSString) { return cached.image }
        guard let image = try? ImageSourceReader.orientedImage(URL(fileURLWithPath: path), maxLongEdge: 4096) else { return nil }
        logoCache.setObject(DecodedImage(image), forKey: path as NSString)
        return image
    }
}
