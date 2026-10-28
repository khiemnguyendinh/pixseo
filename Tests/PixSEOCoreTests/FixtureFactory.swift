import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Builds test images in code (no binary fixtures in the repo).
enum FixtureFactory {
    static func makeDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("pixseo-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Photo-like pixels: gradient plus deterministic noise, so compressed sizes are realistic.
    /// A solid red square marks the top-left corner (of the stored pixels) for orientation checks.
    static func photo(width: Int, height: Int, colorSpace: CGColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!, alpha: Bool = false) -> CGImage {
        var seed: UInt32 = 2_463_534_242
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                seed ^= seed << 13; seed ^= seed >> 17; seed ^= seed << 5
                let noise = Int(seed % 48)
                let i = (y * width + x) * 4
                bytes[i] = UInt8(min(255, x * 200 / max(width, 1) + noise))
                bytes[i + 1] = UInt8(min(255, y * 200 / max(height, 1) + noise))
                bytes[i + 2] = UInt8(min(255, 120 + noise))
                bytes[i + 3] = 255
                if x < width / 10, y < height / 10 { bytes[i] = 255; bytes[i + 1] = 0; bytes[i + 2] = 0 }
                if alpha, x > width / 2 { bytes[i] = 0; bytes[i + 1] = 0; bytes[i + 2] = 0; bytes[i + 3] = 0 }
            }
        }
        let context = CGContext(data: &bytes, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                                space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        return context.makeImage()!
    }

    /// Writes frames to a file of `type` with optional per-image properties (EXIF, GPS, orientation).
    @discardableResult
    static func write(_ frames: [CGImage], to url: URL, type: UTType, properties: [CFString: Any] = [:],
                      fileProperties: [CFString: Any] = [:]) throws -> URL {
        let destination = CGImageDestinationCreateWithURL(url as CFURL, type.identifier as CFString, frames.count, nil)!
        if !fileProperties.isEmpty { CGImageDestinationSetProperties(destination, fileProperties as CFDictionary) }
        for frame in frames { CGImageDestinationAddImage(destination, frame, properties as CFDictionary) }
        guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
        return url
    }

    static var gpsAndExif: [CFString: Any] { [
        kCGImagePropertyGPSDictionary: [kCGImagePropertyGPSLatitude: 10.7769, kCGImagePropertyGPSLatitudeRef: "N",
                                        kCGImagePropertyGPSLongitude: 106.7009, kCGImagePropertyGPSLongitudeRef: "E"],
        kCGImagePropertyExifDictionary: [kCGImagePropertyExifLensModel: "Test Lens"],
    ] }

    static func properties(of url: URL, index: Int = 0) -> [CFString: Any] {
        let source = CGImageSourceCreateWithURL(url as CFURL, nil)!
        return CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any] ?? [:]
    }

    static func decode(_ url: URL) -> (image: CGImage, type: String, frames: Int) {
        let source = CGImageSourceCreateWithURL(url as CFURL, nil)!
        return (CGImageSourceCreateImageAtIndex(source, 0, nil)!, CGImageSourceGetType(source)! as String, CGImageSourceGetCount(source))
    }

    /// RGBA of one pixel (x, y from top-left) after drawing into sRGB.
    static func pixel(_ image: CGImage, x: Int, y: Int) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: 4)
        let context = CGContext(data: &bytes, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.draw(image, in: CGRect(x: -x, y: y - image.height + 1, width: image.width, height: image.height))
        return bytes
    }
}
