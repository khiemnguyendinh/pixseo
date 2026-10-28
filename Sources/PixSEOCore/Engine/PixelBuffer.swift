import CoreGraphics

/// 8-bit RGBA, premultiplied, sRGB copy of a CGImage's pixels. Used where raw pixels are needed:
/// handing them to libwebp and counting colors.
struct PixelBuffer {
    let width: Int
    let height: Int
    var bytes: [UInt8]
    var bytesPerRow: Int { width * 4 }

    init?(_ image: CGImage) {
        width = image.width
        height = image.height
        bytes = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return nil }
    }

    /// True when any pixel is not fully opaque.
    var hasTransparency: Bool {
        stride(from: 3, to: bytes.count, by: 4).contains { bytes[$0] < 255 }
    }

    /// Converts to straight (non-premultiplied) alpha, which libwebp expects.
    mutating func unpremultiply() {
        for i in stride(from: 0, to: bytes.count, by: 4) {
            let alpha = Int(bytes[i + 3])
            guard alpha > 0, alpha < 255 else { continue }
            for c in 0..<3 {
                bytes[i + c] = UInt8(min(255, (Int(bytes[i + c]) * 255 + alpha / 2) / alpha))
            }
        }
    }
}
