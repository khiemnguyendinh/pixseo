import Foundation

/// Which size goes at the end of the file name: `khai-giang-k15-1920.webp`.
public enum SizeSuffix: String, Codable, Sendable, CaseIterable {
    case width, longEdge, dimensions, none

    func text(for size: PixelSize) -> String? {
        switch self {
        case .width: String(size.width)
        case .longEdge: String(size.longEdge)
        case .dimensions: "\(size.width)x\(size.height)"
        case .none: nil
        }
    }
}

/// How a batch of images is named.
public enum BatchNameMode: Equatable, Sendable {
    /// Each image keeps a slug of its own name (or what the user typed for a single image).
    case individual
    /// One base for all images, numbered: `khai-giang-k15-01-1920.webp`.
    case shared(String)
}

/// Builds collision-free SEO file names. Never returns a name that already exists on disk or
/// that another image in the same batch will use, so nothing is ever overwritten.
public struct OutputFileNamer: Sendable {
    public struct Item: Sendable {
        /// The user's text for this image, or the source file name when they typed nothing.
        public var input: String
        public var outputSize: PixelSize
        public var directory: URL

        public init(input: String, outputSize: PixelSize, directory: URL) {
            self.input = input
            self.outputSize = outputSize
            self.directory = directory
        }
    }

    public var suffix: SizeSuffix
    public var maxBaseLength: Int
    public var fileExists: @Sendable (URL) -> Bool

    public init(
        suffix: SizeSuffix = .width,
        maxBaseLength: Int = SEOSlugger.defaultMaxLength,
        fileExists: @escaping @Sendable (URL) -> Bool = { FileManager.default.fileExists(atPath: $0.path) }
    ) {
        self.suffix = suffix
        self.maxBaseLength = maxBaseLength
        self.fileExists = fileExists
    }

    /// Destination URLs, in the same order as `items`.
    public func plan(_ items: [Item], mode: BatchNameMode, fileExtension: String) -> [URL] {
        let digits = max(2, String(items.count).count)
        var taken = Set<String>()
        return items.enumerated().map { index, item in
            var base: String
            switch mode {
            case .individual:
                base = slug(item.input)
            case .shared(let shared):
                base = slug(shared)
                if items.count > 1 {
                    base += "-" + String(repeating: "0", count: digits - String(index + 1).count) + String(index + 1)
                }
            }
            let stem = stemWithSuffix(base: base, size: item.outputSize)
            let url = uniqueURL(stem: stem, fileExtension: fileExtension, in: item.directory, taken: &taken)
            return url
        }
    }

    /// Final file name for one image, for showing under the name field while the user types.
    /// Doesn't change what the user typed.
    public func preview(input: String, outputSize: PixelSize, fileExtension: String, in directory: URL) -> String {
        plan([Item(input: input, outputSize: outputSize, directory: directory)], mode: .individual, fileExtension: fileExtension)[0]
            .lastPathComponent
    }

    func slug(_ input: String) -> String {
        SEOSlugger.slugify(SEOSlugger.stripImageExtension(input), maxLength: maxBaseLength)
    }

    /// Appends the size, dropping a size the base already ends with ("banner-1920" + 1920).
    func stemWithSuffix(base: String, size: PixelSize) -> String {
        guard let text = suffix.text(for: size) else { return base }
        var trimmed = base
        for ending in ["-\(text)", "-\(text)px", "-\(size.width)x\(size.height)"] where trimmed.hasSuffix(ending) {
            trimmed.removeLast(ending.count)
            break
        }
        return trimmed.isEmpty ? text : "\(trimmed)-\(text)"
    }

    /// Adds -2, -3… until the name is free on disk and unused in this batch.
    private func uniqueURL(stem: String, fileExtension: String, in directory: URL, taken: inout Set<String>) -> URL {
        var counter = 1
        while true {
            let name = (counter == 1 ? stem : "\(stem)-\(counter)") + "." + fileExtension
            let url = directory.appendingPathComponent(name)
            if !taken.contains(url.path), !fileExists(url) {
                taken.insert(url.path)
                return url
            }
            counter += 1
        }
    }
}
