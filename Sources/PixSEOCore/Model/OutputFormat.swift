import UniformTypeIdentifiers

/// Formats PixSEO can write.
public enum OutputFormat: String, Codable, Sendable, CaseIterable {
    case webp, jpeg, png, gif

    public var fileExtension: String { self == .jpeg ? "jpg" : rawValue }

    public var utType: UTType {
        switch self {
        case .webp: .webP
        case .jpeg: .jpeg
        case .png: .png
        case .gif: .gif
        }
    }

    /// Lossy formats: quality and byte limits apply.
    public var supportsQuality: Bool { self == .webp || self == .jpeg }
    /// Only JPEG and PNG store a resolution; browsers ignore it either way.
    public var supportsPPI: Bool { self == .jpeg || self == .png }
    public var supportsAlpha: Bool { self != .jpeg }
    /// WebP stores 14-bit dimensions.
    public var maxDimension: Int { self == .webp ? 16383 : 65535 }
}

/// Whether an image looks like a photo or a flat graphic. Drives format advice
/// (PNG is a poor choice for photos) in the export panel and the SEO checklist.
public enum ImageContentKind: String, Codable, Sendable {
    case photo, graphic
}
