import CoreGraphics
import CoreImage

/// Pixel work for one frame: rotate and flip, crop, resize with Lanczos, light sharpening,
/// optional flattening onto white, render to 8-bit sRGB, then the watermark.
public enum RenderPipeline {
    private static let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!

    // CIContext is thread-safe and expensive to create, so one is shared.
    private static let context = CIContext(options: [
        .workingColorSpace: CGColorSpace(name: CGColorSpace.extendedLinearSRGB)!,
        .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
        .cacheIntermediates: false,
    ])

    /// - Parameters:
    ///   - image: oriented source frame, possibly already downsampled while decoding.
    ///   - outputSize: final size from `OutputGeometry.outputSize`.
    ///   - flattenOnWhite: fill transparency with white (JPEG).
    public static func render(_ image: CGImage, recipe: EditRecipe, outputSize: PixelSize, flattenOnWhite: Bool) throws -> CGImage {
        var ci = CIImage(cgImage: image)

        if let crop = recipe.crop {
            ci = rotateAndFlip(ci, crop: crop)
            // The crop rect is normalized with a top-left origin; Core Image's origin is bottom-left.
            let size = PixelSize(width: Int(ci.extent.width), height: Int(ci.extent.height))
            let r = OutputGeometry.cropPixelRect(in: size, crop: crop)
            let ciRect = CGRect(x: r.minX, y: CGFloat(size.height) - r.maxY, width: r.width, height: r.height)
            ci = ci.cropped(to: ciRect).moved(to: .zero)
        }

        let target = CGRect(x: 0, y: 0, width: outputSize.width, height: outputSize.height)
        let scaleX = target.width / ci.extent.width
        let scaleY = target.height / ci.extent.height
        if abs(scaleX - 1) > 0.0001 || abs(scaleY - 1) > 0.0001 {
            // Clamping first stops Lanczos from pulling transparent pixels in at the edges.
            let lanczos = CIFilter(name: "CILanczosScaleTransform")!
            lanczos.setValue(ci.clampedToExtent(), forKey: kCIInputImageKey)
            lanczos.setValue(scaleY, forKey: kCIInputScaleKey)
            lanczos.setValue(scaleX / scaleY, forKey: kCIInputAspectRatioKey)
            ci = lanczos.outputImage ?? ci
            if recipe.sharpen, scaleX < 0.67 {
                ci = ci.applyingFilter("CIUnsharpMask", parameters: [kCIInputRadiusKey: 0.5, kCIInputIntensityKey: 0.3])
            }
        }
        ci = ci.cropped(to: target)

        if flattenOnWhite {
            ci = ci.composited(over: CIImage(color: .white).cropped(to: target))
        }

        guard let output = context.createCGImage(ci, from: target, format: .RGBA8, colorSpace: sRGB) else {
            throw ExportError.encodeFailed
        }
        if let watermark = recipe.watermark {
            return WatermarkRenderer.apply(watermark, to: output)
        }
        return output
    }

    /// Runs a tiny image through the full pipeline so Core Image and Metal finish their one-time
    /// setup (about 0.5 s) at app launch instead of on the user's first export.
    public static func prewarm() {
        let tiny = CIContext().createCGImage(CIImage(color: .gray).cropped(to: CGRect(x: 0, y: 0, width: 64, height: 64)),
                                             from: CGRect(x: 0, y: 0, width: 64, height: 64))
        guard let tiny else { return }
        _ = try? render(tiny, recipe: EditRecipe(), outputSize: PixelSize(width: 16, height: 16), flattenOnWhite: true)
    }

    /// Clockwise quarter turns, then horizontal flip; the result is moved back to the origin.
    private static func rotateAndFlip(_ image: CIImage, crop: CropSpec) -> CIImage {
        var ci = image
        if crop.quarterTurns != 0 {
            ci = ci.transformed(by: CGAffineTransform(rotationAngle: -CGFloat(crop.quarterTurns) * .pi / 2))
            ci = ci.moved(to: .zero)
        }
        if crop.flipHorizontal {
            ci = ci.transformed(by: CGAffineTransform(scaleX: -1, y: 1)).moved(to: .zero)
        }
        return ci
    }
}

extension CIImage {
    /// Translates so the extent starts at `origin`, rounding away floating-point drift.
    func moved(to origin: CGPoint) -> CIImage {
        let extent = self.extent
        return transformed(by: CGAffineTransform(translationX: origin.x - extent.minX.rounded(), y: origin.y - extent.minY.rounded()))
    }
}
