import CoreGraphics

/// Size math shared by the engine and the UI. Pure functions, no image access.
public enum OutputGeometry {
    /// Size after rotation and crop, before resizing.
    public static func croppedSize(source: PixelSize, crop: CropSpec?) -> PixelSize {
        guard let crop else { return source }
        let rotated = crop.quarterTurns % 2 == 1 ? source.transposed : source
        let rect = cropPixelRect(in: rotated, crop: crop)
        return PixelSize(width: Int(rect.width), height: Int(rect.height))
    }

    /// Crop rectangle in pixels, top-left origin, inside the rotated image. Clamped and at least 1 px.
    public static func cropPixelRect(in rotated: PixelSize, crop: CropSpec) -> CGRect {
        let full = CGRect(x: 0, y: 0, width: rotated.width, height: rotated.height)
        // Round origin and size separately: `.integral` grows the rect outward, so floating-point
        // noise turned a 2000 px square into 2001×2000 and a 1:1 export into 1920×1919.
        let raw = CGRect(
            x: (crop.rect.minX * CGFloat(rotated.width)).rounded(), y: (crop.rect.minY * CGFloat(rotated.height)).rounded(),
            width: (crop.rect.width * CGFloat(rotated.width)).rounded(), height: (crop.rect.height * CGFloat(rotated.height)).rounded()
        ).intersection(full)
        guard !raw.isNull, raw.width >= 1, raw.height >= 1 else { return full }
        return raw
    }

    /// Output size for `input` under `resize`, keeping the aspect ratio.
    /// Never enlarges: `notUpscaled` is true when the requested size was bigger than the image.
    public static func outputSize(for input: PixelSize, resize: ResizeSpec) -> (size: PixelSize, notUpscaled: Bool) {
        if let fixed = resize.fixedSize, input.width >= fixed.width, input.height >= fixed.height {
            return (fixed, false)
        }
        guard let target = resize.value, target > 0 else { return (input, false) }
        let current: Int
        switch resize.mode {
        case .width: current = input.width
        case .height: current = input.height
        case .longEdge: current = input.longEdge
        }
        guard target < current else { return (input, target > current) }

        let scale = Double(target) / Double(current)
        let width = max(1, Int((Double(input.width) * scale).rounded()))
        let height = max(1, Int((Double(input.height) * scale).rounded()))
        // Pin the constrained edge exactly so 1920 never comes out as 1919.
        switch resize.mode {
        case .width: return (PixelSize(width: target, height: height), false)
        case .height: return (PixelSize(width: width, height: target), false)
        case .longEdge:
            return input.width >= input.height
                ? (PixelSize(width: target, height: height), false)
                : (PixelSize(width: width, height: target), false)
        }
    }

    /// Long edge to decode the source at: twice the scale actually needed (Lanczos then has
    /// enough detail to work with), never more than the source itself.
    public static func decodeLongEdge(source: PixelSize, cropped: PixelSize, output: PixelSize) -> Int {
        let scale = Double(output.width) / Double(max(cropped.width, 1))
        let needed = Int((Double(source.longEdge) * min(1, scale * 2)).rounded(.up))
        return min(source.longEdge, max(needed, 1))
    }
}
