import CoreGraphics
import Foundation
import libwebp

/// Lossy WebP through libwebp's advanced API.
///
/// - `method = 4`: good size/speed balance; estimates and saves use the same setting so the
///   estimated bytes can be written as is.
/// - `use_sharp_yuv`: keeps red and blue text on banners from bleeding during chroma subsampling.
enum WebPEncoder {
    static func encode(_ image: CGImage, quality: Double, keepAlpha: Bool) throws -> Data {
        guard image.width <= OutputFormat.webp.maxDimension, image.height <= OutputFormat.webp.maxDimension else {
            throw ExportError.dimensionTooLarge(max: OutputFormat.webp.maxDimension)
        }
        guard var pixels = PixelBuffer(image) else { throw ExportError.encodeFailed }
        let withAlpha = keepAlpha && pixels.hasTransparency
        if withAlpha { pixels.unpremultiply() }

        var config = WebPConfig()
        guard WebPConfigInit(&config) != 0 else { throw ExportError.encodeFailed }
        config.quality = Float(min(max(quality, 0), 1) * 100)
        config.method = 4
        config.use_sharp_yuv = 1
        config.alpha_quality = 90
        guard WebPValidateConfig(&config) != 0 else { throw ExportError.encodeFailed }

        var picture = WebPPicture()
        guard WebPPictureInit(&picture) != 0 else { throw ExportError.encodeFailed }
        defer { WebPPictureFree(&picture) }
        picture.width = Int32(pixels.width)
        picture.height = Int32(pixels.height)
        picture.use_argb = 1

        let imported = pixels.bytes.withUnsafeBufferPointer { buffer in
            withAlpha
                ? WebPPictureImportRGBA(&picture, buffer.baseAddress, Int32(pixels.bytesPerRow))
                : WebPPictureImportRGBX(&picture, buffer.baseAddress, Int32(pixels.bytesPerRow))
        }
        guard imported != 0 else { throw ExportError.encodeFailed }

        var writer = WebPMemoryWriter()
        WebPMemoryWriterInit(&writer)
        defer { WebPMemoryWriterClear(&writer) }
        let encoded = withUnsafeMutablePointer(to: &writer) { writerPointer -> Int32 in
            picture.writer = WebPMemoryWrite
            picture.custom_ptr = UnsafeMutableRawPointer(writerPointer)
            return WebPEncode(&config, &picture)
        }
        guard encoded != 0, let memory = writer.mem else { throw ExportError.encodeFailed }
        return Data(bytes: memory, count: writer.size)
    }
}
