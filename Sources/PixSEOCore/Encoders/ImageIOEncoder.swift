import Foundation
import ImageIO

/// JPEG, PNG and GIF through ImageIO. Only the properties set here are written, so source
/// metadata (EXIF, GPS, IPTC, XMP) never reaches the output.
enum ImageIOEncoder {
    static func encodeStill(_ image: CGImage, format: OutputFormat, quality: Double, ppi: Int) throws -> Data {
        var props: [CFString: Any] = [kCGImagePropertyOrientation: 1]
        if format.supportsPPI {
            props[kCGImagePropertyDPIWidth] = ppi
            props[kCGImagePropertyDPIHeight] = ppi
        }
        if format == .jpeg {
            props[kCGImageDestinationLossyCompressionQuality] = quality
            props[kCGImagePropertyJFIFDictionary] = [kCGImagePropertyJFIFIsProgressive: true]
        }
        return try write(format: format, frameCount: 1) { destination in
            CGImageDestinationAddImage(destination, image, props as CFDictionary)
        }
    }

    /// Animated GIF. Frames are produced and added one at a time so a long animation never
    /// sits in memory all at once.
    static func encodeAnimatedGIF(frameCount: Int, delays: [Double], loopCount: Int, frame: (Int) throws -> CGImage) throws -> Data {
        try write(format: .gif, frameCount: frameCount, fileProperties: [
            kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: loopCount],
        ]) { destination in
            for index in 0..<frameCount {
                try autoreleasepool {
                    // Browsers treat delays under 0.02 s as 0.1 s; keep the source's intent.
                    let delay = max(0.02, index < delays.count ? delays[index] : 0.1)
                    let props: [CFString: Any] = [kCGImagePropertyGIFDictionary: [
                        kCGImagePropertyGIFDelayTime: delay,
                        kCGImagePropertyGIFUnclampedDelayTime: delay,
                    ]]
                    CGImageDestinationAddImage(destination, try frame(index), props as CFDictionary)
                }
            }
        }
    }

    private static func write(
        format: OutputFormat, frameCount: Int, fileProperties: [CFString: Any] = [:],
        addImages: (CGImageDestination) throws -> Void
    ) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, format.utType.identifier as CFString, frameCount, nil) else {
            throw ExportError.encodeFailed
        }
        if !fileProperties.isEmpty { CGImageDestinationSetProperties(destination, fileProperties as CFDictionary) }
        try addImages(destination)
        guard CGImageDestinationFinalize(destination) else { throw ExportError.encodeFailed }
        return data as Data
    }
}
