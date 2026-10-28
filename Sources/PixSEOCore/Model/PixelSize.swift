/// Integer pixel dimensions of an image.
public struct PixelSize: Hashable, Codable, Sendable, CustomStringConvertible {
    public var width: Int
    public var height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    public var longEdge: Int { max(width, height) }
    public var transposed: PixelSize { PixelSize(width: height, height: width) }
    public var description: String { "\(width)×\(height)" }
}
