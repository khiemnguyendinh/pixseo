import Foundation

/// Crop ratios offered in the editor. `openGraph` is 1200×630, the size social networks use
/// for link previews, so it also fixes the output width.
public enum AspectRatioPreset: String, CaseIterable, Codable, Sendable {
    case free, original, square, r4x5, r3x4, r2x3, r3x2, r4x3, r16x9, r9x16, openGraph

    public var label: String {
        switch self {
        case .free: "Tự do"
        case .original: "Gốc"
        case .square: "1:1"
        case .r4x5: "4:5"
        case .r3x4: "3:4"
        case .r2x3: "2:3"
        case .r3x2: "3:2"
        case .r4x3: "4:3"
        case .r16x9: "16:9"
        case .r9x16: "9:16"
        case .openGraph: "OG 1200×630"
        }
    }

    /// Width ÷ height in pixels, or `nil` for a free crop. `original` uses the image itself.
    public func ratio(original: PixelSize) -> Double? {
        switch self {
        case .free: nil
        case .original: Double(original.width) / Double(max(original.height, 1))
        case .square: 1
        case .r4x5: 4.0 / 5
        case .r3x4: 3.0 / 4
        case .r2x3: 2.0 / 3
        case .r3x2: 3.0 / 2
        case .r4x3: 4.0 / 3
        case .r16x9: 16.0 / 9
        case .r9x16: 9.0 / 16
        case .openGraph: 1200.0 / 630
        }
    }

    /// Output width the preset implies (only Open Graph has one).
    public var fixedWidth: Int? { self == .openGraph ? 1200 : nil }

    /// Ratios that look different when swapped (portrait ↔ landscape).
    public var canSwapOrientation: Bool {
        switch self {
        case .free, .square, .original, .openGraph: false
        default: true
        }
    }
}
