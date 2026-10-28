import CoreGraphics

/// Picks where a watermark is least in the way, and which color reads best there.
public enum WatermarkPlacementAdvisor {
    private static let grid = 48

    /// The corner with the least detail (sum of brightness changes), so the mark doesn't sit on
    /// faces, text or busy texture.
    public static func emptiestCorner(of image: CGImage) -> WatermarkAnchor {
        guard let luminance = luminanceGrid(image, side: grid) else { return .bottomRight }
        return emptiestCorner(luminance: luminance, width: grid, height: grid)
    }

    /// Same, on a row-major brightness grid (0…1). Ties prefer bottom-right, the usual spot.
    public static func emptiestCorner(luminance: [Double], width: Int, height: Int) -> WatermarkAnchor {
        let (cw, ch) = (max(width / 3, 2), max(height / 3, 2))
        func detail(_ x0: Int, _ y0: Int) -> Double {
            var total = 0.0
            for y in y0..<(y0 + ch) {
                for x in x0..<(x0 + cw) {
                    let v = luminance[y * width + x]
                    if x + 1 < x0 + cw { total += abs(v - luminance[y * width + x + 1]) }
                    if y + 1 < y0 + ch { total += abs(v - luminance[(y + 1) * width + x]) }
                }
            }
            return total
        }
        let scores: [(WatermarkAnchor, Double)] = [
            (.bottomRight, detail(width - cw, height - ch)),
            (.bottomLeft, detail(0, height - ch)),
            (.topRight, detail(width - cw, 0)),
            (.topLeft, detail(0, 0)),
        ]
        // Strictly better by 5% to move away from bottom-right.
        return scores.dropFirst().reduce(scores[0]) { best, next in next.1 < best.1 * 0.95 ? next : best }.0
    }

    /// Average brightness (0…1) under `rect` (pixels, top-left origin).
    public static func averageLuminance(of image: CGImage, in rect: CGRect) -> Double {
        // CGImage cropping already uses a top-left origin.
        guard let region = image.cropping(to: rect.integral), let values = luminanceGrid(region, side: 8) else { return 0.5 }
        return values.reduce(0, +) / Double(values.count)
    }

    /// Suggested text color for the area: black on light backgrounds, white on dark ones.
    public static func suggestedColor(backgroundLuminance: Double) -> RGBAColor {
        backgroundLuminance > 0.5 ? .black : .white
    }

    private static func luminanceGrid(_ image: CGImage, side: Int) -> [Double]? {
        var bytes = [UInt8](repeating: 0, count: side * side)
        let ok = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: side, height: side, bitsPerComponent: 8,
                                          bytesPerRow: side, space: CGColorSpaceCreateDeviceGray(),
                                          bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return false }
            context.interpolationQuality = .medium
            context.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
            return true
        }
        return ok ? bytes.map { Double($0) / 255 } : nil
    }
}
