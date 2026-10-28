import Foundation

/// What the user asked for from the Finder menu or drag and drop.
public enum IntakeAction: String, Sendable, CaseIterable {
    case resize, crop, watermark, open
}

/// A request to process image files.
///
/// The sandboxed Finder extension cannot share storage with the app, so it hands requests over
/// as `pixseo://run?a=resize&w=1920&f=/path&f=/path` URLs. Large selections are split into
/// chunks that carry the same batch id; `IntakeBatchAssembler` joins them back together.
public struct IntakeRequest: Equatable, Sendable {
    public static let scheme = "pixseo"
    public static let host = "run"
    public static let widthRange = 16...16384
    public static let maxFilesPerURL = 50

    /// One chunk of a request that was split across several URLs.
    public struct Chunk: Equatable, Sendable {
        public var batchID: String
        public var index: Int
        public var count: Int

        public init(batchID: String, index: Int, count: Int) {
            self.batchID = batchID
            self.index = index
            self.count = count
        }
    }

    public var action: IntakeAction
    /// Target output width in pixels; `nil` means "let the user choose".
    public var width: Int?
    public var files: [URL]
    public var chunk: Chunk?

    public init(action: IntakeAction, width: Int? = nil, files: [URL], chunk: Chunk? = nil) {
        self.action = action
        self.width = width
        self.files = files
        self.chunk = chunk
    }

    // MARK: Encoding

    /// URLs to open, one per chunk of at most `maxFilesPerURL` files.
    public func makeURLs(batchID: String = UUID().uuidString) -> [URL] {
        let groups = stride(from: 0, to: max(files.count, 1), by: Self.maxFilesPerURL).map {
            Array(files[$0..<min($0 + Self.maxFilesPerURL, files.count)])
        }
        return groups.enumerated().compactMap { index, group in
            var items = [("a", action.rawValue)]
            if let width { items.append(("w", String(width))) }
            if groups.count > 1 {
                items += [("b", batchID), ("i", String(index)), ("n", String(groups.count))]
            }
            items += group.map { ("f", $0.path) }

            var components = URLComponents()
            components.scheme = Self.scheme
            components.host = Self.host
            // URLComponents leaves "&", "=" and "+" unescaped in query values, which would break
            // file names that contain them, so values are escaped with a stricter set.
            components.percentEncodedQuery = items
                .map { "\($0.0)=\($0.1.addingPercentEncoding(withAllowedCharacters: .pixseoQueryValue) ?? "")" }
                .joined(separator: "&")
            return components.url
        }
    }

    // MARK: Decoding

    /// Parses a `pixseo://run` URL. Returns `nil` for anything malformed: wrong scheme or host,
    /// unknown action, width out of range, relative paths, or an inconsistent chunk header.
    public init?(url: URL) {
        guard url.scheme == Self.scheme, url.host == Self.host,
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
              let action = items.first(where: { $0.name == "a" })?.value.flatMap(IntakeAction.init(rawValue:))
        else { return nil }

        var width: Int?
        if let raw = items.first(where: { $0.name == "w" })?.value {
            guard let value = Int(raw), Self.widthRange.contains(value) else { return nil }
            width = value
        }

        let paths = items.filter { $0.name == "f" }.compactMap(\.value)
        guard paths.allSatisfy({ $0.hasPrefix("/") }) else { return nil }

        var chunk: Chunk?
        if let batchID = items.first(where: { $0.name == "b" })?.value {
            guard let index = items.first(where: { $0.name == "i" })?.value.flatMap({ Int($0) }),
                  let count = items.first(where: { $0.name == "n" })?.value.flatMap({ Int($0) }),
                  count > 0, (0..<count).contains(index), !batchID.isEmpty
            else { return nil }
            chunk = Chunk(batchID: batchID, index: index, count: count)
        }

        self.init(action: action, width: width, files: paths.map { URL(fileURLWithPath: $0) }, chunk: chunk)
    }
}

extension CharacterSet {
    /// Unreserved characters plus "/" so paths stay readable in logs.
    static let pixseoQueryValue: CharacterSet = {
        var set = CharacterSet.alphanumerics
        set.insert(charactersIn: "-._~/")
        return set
    }()
}
