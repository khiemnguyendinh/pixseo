import Foundation
import ImageIO
import UniformTypeIdentifiers

/// What PixSEO needs to know about a source file before processing it.
public struct SourceImageInfo: Sendable {
    public let url: URL
    /// Size as displayed, i.e. after EXIF orientation.
    public let pixelSize: PixelSize
    /// The file has an alpha channel (it may still be fully opaque).
    public let hasAlpha: Bool
    /// Some pixels are actually see-through (checked on a 256 px thumbnail).
    public let hasTransparency: Bool
    public let frameCount: Int
    /// Seconds per frame for animated images.
    public let frameDelays: [Double]
    /// 0 = loop forever.
    public let loopCount: Int
    public let byteCount: Int
    public let typeIdentifier: String
    public let contentKind: ImageContentKind
}

/// Reads images with ImageIO. Decoding always applies EXIF orientation, and downsamples while
/// decoding when a smaller size is enough, which is fast and keeps memory low.
public enum ImageSourceReader {
    public static func readInfo(_ url: URL) throws -> SourceImageInfo {
        let source = try makeSource(url)
        guard let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = props[kCGImagePropertyPixelWidth] as? Int,
              let height = props[kCGImagePropertyPixelHeight] as? Int
        else { throw ExportError.unreadable }

        // Orientations 5–8 rotate by 90°, so the displayed size is transposed.
        let orientation = props[kCGImagePropertyOrientation] as? Int ?? 1
        let stored = PixelSize(width: width, height: height)
        let frameCount = CGImageSourceGetCount(source)
        let type = CGImageSourceGetType(source) as String? ?? ""
        let hasAlpha = props[kCGImagePropertyHasAlpha] as? Bool ?? false
        let fileProps = CGImageSourceCopyProperties(source, nil) as? [CFString: Any]
        let thumbnail = hasAlpha || !isPhotoType(type) ? smallThumbnail(source) : nil
        let hasTransparency = thumbnail?.hasTransparency ?? false
        let gifFile = fileProps?[kCGImagePropertyGIFDictionary] as? [CFString: Any]

        return SourceImageInfo(
            url: url,
            pixelSize: orientation >= 5 ? stored.transposed : stored,
            hasAlpha: hasAlpha,
            hasTransparency: hasTransparency,
            frameCount: frameCount,
            frameDelays: (0..<frameCount).map { frameDelay(source, index: $0) },
            loopCount: gifFile?[kCGImagePropertyGIFLoopCount] as? Int ?? 0,
            byteCount: (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0,
            typeIdentifier: type,
            contentKind: contentKind(type: type, hasTransparency: hasTransparency, thumbnail: thumbnail)
        )
    }

    /// Decodes frame `index` with orientation applied and its long edge at most `maxLongEdge`.
    /// Pass the source's own long edge for a full-size decode.
    public static func orientedImage(_ url: URL, index: Int = 0, maxLongEdge: Int) throws -> CGImage {
        let source = try makeSource(url)
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxLongEdge,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, index, options as CFDictionary) else {
            throw ExportError.unreadable
        }
        return image
    }

    /// Canvas preview for the editor: oriented, long edge at most 2048 px.
    public static func preview(_ url: URL, maxLongEdge: Int = 2048) throws -> CGImage {
        try orientedImage(url, maxLongEdge: maxLongEdge)
    }

    /// Starts downloading an iCloud Drive file that is only a placeholder and waits for it.
    public static func ensureDownloaded(_ url: URL, timeout: TimeInterval = 30) throws {
        let key = URLResourceKey.ubiquitousItemDownloadingStatusKey
        func status() -> URLUbiquitousItemDownloadingStatus? {
            var copy = url
            copy.removeAllCachedResourceValues()
            return try? copy.resourceValues(forKeys: [key]).ubiquitousItemDownloadingStatus
        }
        guard let initial = status(), initial != .current else { return }
        try FileManager.default.startDownloadingUbiquitousItem(at: url)
        let deadline = Date().addingTimeInterval(timeout)
        while status() != .current {
            guard Date() < deadline else { throw ExportError.iCloudNotDownloaded }
            Thread.sleep(forTimeInterval: 0.25)
        }
    }

    static func makeSource(_ url: URL) throws -> CGImageSource {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil), CGImageSourceGetCount(source) > 0 else {
            throw ExportError.unreadable
        }
        return source
    }

    private static func frameDelay(_ source: CGImageSource, index: Int) -> Double {
        guard let props = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any] else { return 0.1 }
        let keyed: [(CFString, CFString, CFString)] = [
            (kCGImagePropertyGIFDictionary, kCGImagePropertyGIFUnclampedDelayTime, kCGImagePropertyGIFDelayTime),
            (kCGImagePropertyWebPDictionary, kCGImagePropertyWebPUnclampedDelayTime, kCGImagePropertyWebPDelayTime),
            (kCGImagePropertyPNGDictionary, kCGImagePropertyAPNGUnclampedDelayTime, kCGImagePropertyAPNGDelayTime),
        ]
        for (dictKey, unclamped, clamped) in keyed {
            guard let dict = props[dictKey] as? [CFString: Any] else { continue }
            if let delay = (dict[unclamped] as? Double) ?? (dict[clamped] as? Double), delay > 0 { return delay }
        }
        return 0.1
    }

    private static func isPhotoType(_ type: String) -> Bool {
        guard let utType = UTType(type) else { return false }
        return utType.conforms(to: .jpeg) || utType.conforms(to: .heic) || utType.conforms(to: .heif)
    }

    private static func smallThumbnail(_ source: CGImageSource) -> PixelBuffer? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 256,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary).flatMap(PixelBuffer.init)
    }

    /// JPEG/HEIC sources are photos. Otherwise an opaque image with many distinct colors
    /// (counted on the 256 px thumbnail) is a photo; logos, charts and screenshots are graphics.
    private static func contentKind(type: String, hasTransparency: Bool, thumbnail: PixelBuffer?) -> ImageContentKind {
        if isPhotoType(type) { return .photo }
        if hasTransparency { return .graphic }
        guard let pixels = thumbnail else { return .photo }
        var colors = Set<UInt32>()
        for i in stride(from: 0, to: pixels.bytes.count, by: 4) {
            colors.insert(UInt32(pixels.bytes[i]) << 16 | UInt32(pixels.bytes[i + 1]) << 8 | UInt32(pixels.bytes[i + 2]))
            if colors.count > 4096 { return .photo }
        }
        return .graphic
    }
}
