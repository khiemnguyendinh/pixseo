import Foundation

/// Quick "is this image web-ready" check shown as a small badge. Never blocks saving.
public struct SEOChecklist: Sendable, Equatable {
    public enum Level: Int, Sendable, Comparable {
        case good, fair, poor
        public static func < (a: Level, b: Level) -> Bool { a.rawValue < b.rawValue }
    }

    public enum Item: Sendable, Equatable {
        case fileSize(bytes: Int)
        case dimensions(longEdge: Int)
        case name(words: Int, meaningful: Bool)
        case format(OutputFormat, photo: Bool, animated: Bool)
        case metadataStripped
        case altText(present: Bool)
    }

    public struct Entry: Sendable, Equatable {
        public let item: Item
        public let level: Level
    }

    public let entries: [Entry]

    public init(bytes: Int?, outputSize: PixelSize?, slug: String, format: OutputFormat,
                contentKind: ImageContentKind?, frameCount: Int, hasAltText: Bool) {
        var entries: [Entry] = []
        if let bytes { entries.append(Entry(item: .fileSize(bytes: bytes), level: Self.level(bytes, good: 200 * 1024, fair: 500 * 1024))) }
        if let outputSize {
            entries.append(Entry(item: .dimensions(longEdge: outputSize.longEdge), level: Self.level(outputSize.longEdge, good: 2560, fair: 3840)))
        }
        let words = slug.split(separator: "-").filter { !$0.allSatisfy(\.isNumber) }.count
        let meaningful = !MeaninglessNameDetector.isMeaningless(slug) && slug != SEOSlugger.fallback
        let nameLevel: Level = !meaningful ? .poor : words > 8 ? .fair : words < 2 ? .fair : .good
        entries.append(Entry(item: .name(words: words, meaningful: meaningful), level: nameLevel))

        let photo = contentKind == .photo
        let animated = frameCount > 1
        let formatLevel: Level
        switch format {
        case .webp, .jpeg: formatLevel = .good
        case .png: formatLevel = photo ? .fair : .good
        case .gif: formatLevel = animated ? .fair : .poor
        }
        entries.append(Entry(item: .format(format, photo: photo, animated: animated), level: formatLevel))
        // PixSEO always strips EXIF/GPS.
        entries.append(Entry(item: .metadataStripped, level: .good))
        entries.append(Entry(item: .altText(present: hasAltText), level: hasAltText ? .good : .fair))
        self.entries = entries
    }

    /// Entries that need attention.
    public var issues: [Entry] { entries.filter { $0.level != .good } }

    public var worst: Level { entries.map(\.level).max() ?? .good }

    static func level(_ value: Int, good: Int, fair: Int) -> Level {
        value <= good ? .good : value <= fair ? .fair : .poor
    }
}
