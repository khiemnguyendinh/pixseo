import CoreGraphics

/// Which edge a target size applies to. Default is width (decided 2026-10-28).
public enum ResizeMode: String, Codable, Sendable, CaseIterable {
    case width, longEdge, height
}

public struct ResizeSpec: Codable, Sendable, Hashable {
    public var mode: ResizeMode
    /// Target size in pixels for `mode`; `nil` keeps the size after cropping.
    public var value: Int?
    /// Exact output size (Open Graph 1200×630). Used when the crop is at least this big, so pixel
    /// rounding of the crop can't turn 630 into 629; a smaller crop falls back to `value`.
    public var fixedSize: PixelSize?

    public init(mode: ResizeMode = .width, value: Int? = nil, fixedSize: PixelSize? = nil) {
        self.mode = mode
        self.value = value
        self.fixedSize = fixedSize
    }
}

/// Rotation, flip and crop, applied in that order after EXIF orientation.
public struct CropSpec: Codable, Sendable, Hashable {
    /// Normalized (0…1) rectangle, top-left origin, in the rotated and flipped image the user sees.
    public var rect: CGRect
    /// Clockwise quarter turns, 0…3.
    public var quarterTurns: Int
    public var flipHorizontal: Bool

    public init(rect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1), quarterTurns: Int = 0, flipHorizontal: Bool = false) {
        self.rect = rect
        self.quarterTurns = ((quarterTurns % 4) + 4) % 4
        self.flipHorizontal = flipHorizontal
    }
}

/// Everything done to the pixels before encoding.
public struct EditRecipe: Codable, Sendable, Hashable {
    public var crop: CropSpec?
    public var resize: ResizeSpec
    /// Light unsharp mask after a strong downscale, which ImageIO and Lanczos both soften.
    public var sharpen: Bool
    /// Drawn last, at the output size.
    public var watermark: WatermarkSpec?

    public init(crop: CropSpec? = nil, resize: ResizeSpec = ResizeSpec(), sharpen: Bool = true, watermark: WatermarkSpec? = nil) {
        self.crop = crop
        self.resize = resize
        self.sharpen = sharpen
        self.watermark = watermark
    }
}

/// How the result is encoded.
public struct ExportSettings: Codable, Sendable, Hashable {
    public var format: OutputFormat
    /// 0…1, used by WebP and JPEG.
    public var quality: Double
    /// Upper bound for the file size; quality is lowered (not below 0.40) to meet it.
    public var targetBytes: Int?
    /// Written to JPEG and PNG only.
    public var ppi: Int

    public init(format: OutputFormat = .webp, quality: Double = 0.80, targetBytes: Int? = nil, ppi: Int = 72) {
        self.format = format
        self.quality = quality
        self.targetBytes = targetBytes
        self.ppi = ppi
    }
}
