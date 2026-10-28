import Foundation

/// Things the user should know about an export that still succeeded.
public enum ExportWarning: Hashable, Sendable {
    /// The source is smaller than the requested size; it was kept as is, never enlarged.
    case notUpscaled(original: PixelSize)
    /// An animated source was written to a still format; only the first frame was kept.
    case animationDropped
    /// JPEG has no transparency; transparent areas were filled with white.
    case alphaFlattened
    /// The byte limit couldn't be met even at the lowest quality. `suggestedWidth` is a smaller
    /// preset worth trying; `nil` means the format is lossless and WebP would help instead.
    case targetNotMet(suggestedWidth: Int?)
    /// The chosen format doesn't store PPI (WebP, GIF).
    case ppiIgnored
    /// The new file is bigger than the original, which was already well compressed.
    case largerThanSource(percent: Int)
}

public enum ExportError: Error, Equatable, Sendable {
    case unreadable
    case iCloudNotDownloaded
    case permissionDenied(directory: URL)
    case destinationExists(URL)
    case dimensionTooLarge(max: Int)
    case encodeFailed
    case diskFull
    case cancelled
}

/// Encoded bytes that haven't been written yet. Kept by the UI after estimating the size so
/// that saving with unchanged settings writes immediately instead of encoding again.
public struct RenderedOutput: Sendable {
    public let data: Data
    public let pixelSize: PixelSize
    public let sourceBytes: Int
    /// Quality actually used (lower than requested when a byte limit applied).
    public let quality: Double
    public let warnings: [ExportWarning]
}

public struct ExportResult: Sendable {
    public let url: URL
    public let bytes: Int
    public let pixelSize: PixelSize
    public let sourceBytes: Int
    public let warnings: [ExportWarning]

    /// 0.96 means the new file is 96% smaller.
    public var savedRatio: Double {
        sourceBytes > 0 ? 1 - Double(bytes) / Double(sourceBytes) : 0
    }
}
