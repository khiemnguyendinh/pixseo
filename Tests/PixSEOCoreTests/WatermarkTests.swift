import CoreGraphics
import CoreText
import Foundation
import Testing
import UniformTypeIdentifiers
@testable import PixSEOCore

struct WatermarkTests {
    private func solid(_ width: Int, _ height: Int, gray: CGFloat) -> CGImage {
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.setFillColor(CGColor(srgbRed: gray, green: gray, blue: gray, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()!
    }

    /// Opaque red square logo written to a temp file.
    private func logo(_ side: Int = 100) throws -> String {
        let context = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.setFillColor(CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: side, height: side))
        let url = try FixtureFactory.makeDirectory().appendingPathComponent("logo.png")
        return try FixtureFactory.write([context.makeImage()!], to: url, type: .png).path
    }

    /// Bounding box (top-left origin) of pixels that differ from the background.
    private func markBox(_ image: CGImage, background: UInt8) -> CGRect? {
        let buffer = PixelBuffer(image)!
        var (minX, minY, maxX, maxY) = (Int.max, Int.max, -1, -1)
        for y in 0..<image.height {
            for x in 0..<image.width {
                let i = (y * image.width + x) * 4
                if abs(Int(buffer.bytes[i]) - Int(background)) > 8 || abs(Int(buffer.bytes[i + 1]) - Int(background)) > 8 {
                    (minX, minY, maxX, maxY) = (min(minX, x), min(minY, y), max(maxX, x), max(maxY, y))
                }
            }
        }
        return maxX < 0 ? nil : CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
    }

    @Test func widthFollowsOutputSize() throws {
        let spec = WatermarkSpec(kind: .logo(path: try logo()), widthFraction: 0.2, opacity: 1)
        for width in [1920, 1080] {
            let box = try #require(markBox(WatermarkRenderer.apply(spec, to: solid(width, width / 2, gray: 0.5)), background: 128))
            #expect(abs(box.width - Double(width) * 0.2) <= 2)
        }
    }

    @Test(arguments: WatermarkAnchor.allCases)
    func anchorsLandInTheirNinth(_ anchor: WatermarkAnchor) throws {
        let spec = WatermarkSpec(kind: .logo(path: try logo()), widthFraction: 0.1, opacity: 1, anchor: anchor)
        let box = try #require(markBox(WatermarkRenderer.apply(spec, to: solid(900, 600, gray: 0.5)), background: 128))
        #expect(Int(box.midX / 300) == Int(anchor.unit.x * 2), "column")
        #expect(Int(box.midY / 200) == Int(anchor.unit.y * 2), "row")
    }

    @Test func opacityBlends() throws {
        let spec = WatermarkSpec(kind: .logo(path: try logo()), widthFraction: 0.3, opacity: 0.5, anchor: .center)
        let image = WatermarkRenderer.apply(spec, to: solid(400, 400, gray: 0))
        let buffer = PixelBuffer(image)!
        let red = buffer.bytes[(200 * 400 + 200) * 4]
        #expect(abs(Int(red) - 128) <= 6, "half-transparent red over black")
    }

    @Test func vietnameseTextRenders() {
        let spec = WatermarkSpec(kind: .text("Khai giảng K15 · Ưu đãi"), color: .white, widthFraction: 0.4, opacity: 1)
        let box = markBox(WatermarkRenderer.apply(spec, to: solid(1000, 500, gray: 0)), background: 0)
        #expect(box != nil)
        #expect(abs((box?.width ?? 0) - 400) < 20)
    }

    @Test func fontCoverage() {
        #expect(FontCoverage.supportsVietnamese(family: "Helvetica Neue"))
        let missing = CFCharacterSetCreateWithCharactersInString(nil, FontCoverage.vietnameseLetters.replacingOccurrences(of: "ỹ", with: "") as CFString)!
        #expect(!FontCoverage.covers(missing))
    }

    @Test func picksEmptiestCorner() {
        // Busy noise everywhere except the bottom-left third.
        let side = 48
        var seed: UInt32 = 7
        let grid = (0..<(side * side)).map { i -> Double in
            let (x, y) = (i % side, i / side)
            if x < 16, y >= 32 { return 0.5 }
            seed ^= seed << 13; seed ^= seed >> 17; seed ^= seed << 5
            return Double(seed % 100) / 100
        }
        #expect(WatermarkPlacementAdvisor.emptiestCorner(luminance: grid, width: side, height: side) == .bottomLeft)
    }

    @Test func dragSnapsToNearestAnchor() {
        let spec = WatermarkSpec(widthFraction: 0.2)
        let canvas = PixelSize(width: 1000, height: 500)
        let home = WatermarkLayout.frame(markAspect: 0.25, canvas: canvas, spec: spec, anchor: .topLeft).origin
        let (anchor, offset) = WatermarkLayout.anchorAndOffset(forOrigin: CGPoint(x: home.x + 3, y: home.y + 2),
                                                               markAspect: 0.25, canvas: canvas, spec: spec)
        #expect(anchor == .topLeft && offset == .zero)
    }

    @Test func presetStoreRoundTripAndLogoCleanup() throws {
        let dir = try FixtureFactory.makeDirectory()
        let store = WatermarkPresetStore(directory: dir)
        let logoPath = try store.importLogo(from: URL(fileURLWithPath: try logo()))
        let preset = WatermarkPreset(name: "Logo góc phải", spec: WatermarkSpec(kind: .logo(path: logoPath), opacity: 0.7))
        try store.save(preset)
        try store.save(WatermarkPreset(name: "Chữ", spec: WatermarkSpec(kind: .text("© Kstudy"))))

        let reloaded = WatermarkPresetStore(directory: dir)
        #expect(reloaded.presets == store.presets)
        #expect(reloaded.defaultPreset?.id == preset.id, "first saved preset becomes the default")

        try reloaded.delete(preset.id)
        #expect(!FileManager.default.fileExists(atPath: logoPath), "unused logo is removed")
        #expect(reloaded.defaultPreset?.name == "Chữ")
    }
}
