import CoreGraphics
import Foundation
import Testing
import UniformTypeIdentifiers
@testable import PixSEOCore

struct CropMathTests {
    private let size = PixelSize(width: 6000, height: 4000)

    private func pixelRatio(_ r: CGRect) -> Double {
        (r.width * Double(size.width)) / (r.height * Double(size.height))
    }

    @Test func largestRectFillsOneSide() {
        let r = CropMath.largestRect(aspect: 16.0 / 9, in: size)
        #expect(abs(r.width - 1) < 1e-9)
        #expect(abs(pixelRatio(r) - 16.0 / 9) < 1e-6)
        #expect(abs(r.midY - 0.5) < 1e-9)
        let square = CropMath.largestRect(aspect: 1, in: size, centeredOn: CGPoint(x: 0.95, y: 0.5))
        #expect(abs(square.maxX - 1) < 1e-9, "clamped to the right edge")
    }

    @Test func cornerDragKeepsRatioExactly() {
        let start = CropMath.largestRect(aspect: 16.0 / 9, in: size)
        let dragged = CropMath.dragged(start, handle: .bottomRight, to: CGPoint(x: 0.6, y: 0.9), aspect: 16.0 / 9, in: size)
        #expect(abs(pixelRatio(dragged) - 16.0 / 9) < 1e-6)
        #expect(abs(dragged.minX - start.minX) < 1e-9 && abs(dragged.minY - start.minY) < 1e-9, "top-left corner stays put")
    }

    @Test func edgeDragGrowsAroundCenterLine() {
        let start = CGRect(x: 0.3, y: 0.3, width: 0.2, height: 0.3)
        let dragged = CropMath.dragged(start, handle: .right, to: CGPoint(x: 0.7, y: 0.5), aspect: 1, in: size)
        #expect(abs(pixelRatio(dragged) - 1) < 1e-6)
        #expect(abs(dragged.midY - start.midY) < 1e-9)
        #expect(abs(dragged.minX - 0.3) < 1e-9)
    }

    @Test func dragStopsAtImageEdges() {
        let start = CGRect(x: 0.5, y: 0.5, width: 0.2, height: 0.2)
        let free = CropMath.dragged(start, handle: .bottomRight, to: CGPoint(x: 1.4, y: 1.3), aspect: nil, in: size)
        #expect(free.maxX <= 1 + 1e-9 && free.maxY <= 1 + 1e-9)
        let locked = CropMath.dragged(start, handle: .bottomRight, to: CGPoint(x: 1.4, y: 1.3), aspect: 16.0 / 9, in: size)
        #expect(locked.maxX <= 1 + 1e-9 && locked.maxY <= 1 + 1e-9)
        #expect(abs(pixelRatio(locked) - 16.0 / 9) < 1e-6)
    }

    @Test func enforcesMinimumSize() {
        let start = CGRect(x: 0.5, y: 0.5, width: 0.2, height: 0.2)
        let tiny = CropMath.dragged(start, handle: .topLeft, to: CGPoint(x: 0.9, y: 0.9), aspect: nil, in: size)
        #expect(tiny.width * 6000 >= CropMath.minimumPixels - 1e-6)
        #expect(tiny.height * 4000 >= CropMath.minimumPixels - 1e-6)
    }

    @Test func moveIsClamped() {
        let moved = CropMath.moved(CGRect(x: 0.7, y: 0.1, width: 0.2, height: 0.2), by: CGVector(dx: 0.5, dy: -0.5))
        #expect(moved == CGRect(x: 0.8, y: 0, width: 0.2, height: 0.2))
    }

    @Test func fourTurnsAndTwoFlipsReturnHome() {
        let spec = CropSpec(rect: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4))
        let turned = spec.rotatedClockwise().rotatedClockwise().rotatedClockwise().rotatedClockwise()
        #expect(turned.quarterTurns == 0)
        #expect(abs(turned.rect.minX - 0.1) < 1e-9 && abs(turned.rect.height - 0.4) < 1e-9)
        let twice = spec.flippedHorizontally().flippedHorizontally()
        #expect(!twice.flipHorizontal && abs(twice.rect.minX - 0.1) < 1e-9)
        #expect(spec.rotatedClockwise().rotatedCounterclockwise().rect.origin.x - 0.1 < 1e-9)
    }

    /// The crop follows the picture when it's turned after a flip: rendering the turned spec
    /// gives the same pixels as turning the rendered picture.
    @Test func turnAfterFlipMatchesPixels() throws {
        let source = FixtureFactory.photo(width: 60, height: 40)
        let flipped = CropSpec(rect: CGRect(x: 0, y: 0, width: 0.5, height: 1), flipHorizontal: true)
        let before = try render(source, flipped)
        let after = try render(source, flipped.rotatedClockwise())
        #expect(after.width == before.height && after.height == before.width)
        // Top-left of the turned result is the bottom-left of the earlier result.
        #expect(pixel(after, 0, 0) == pixel(before, 0, before.height - 1))
        #expect(pixel(after, after.width - 1, 0) == pixel(before, 0, 0))
    }

    @Test func openGraphComesOutExactly() throws {
        let dir = try FixtureFactory.makeDirectory()
        let url = try FixtureFactory.write([FixtureFactory.photo(width: 1999, height: 1333)], to: dir.appendingPathComponent("og.png"), type: .png)
        let image = PixelSize(width: 1999, height: 1333)
        let rect = CropMath.largestRect(aspect: AspectRatioPreset.openGraph.ratio(original: image)!, in: image)
        let recipe = EditRecipe(crop: CropSpec(rect: rect), resize: ResizeSpec(value: 1200, fixedSize: PixelSize(width: 1200, height: 630)))
        let job = ExportJob(source: url, recipe: recipe, settings: ExportSettings(format: .jpeg), destination: dir.appendingPathComponent("o.jpg"))
        #expect(try ExportService().render(job).pixelSize == PixelSize(width: 1200, height: 630))
    }

    @Test func squareCropOfLandscapeStaysSquare() throws {
        let dir = try FixtureFactory.makeDirectory()
        let url = try FixtureFactory.write([FixtureFactory.photo(width: 3000, height: 2000)], to: dir.appendingPathComponent("s.png"), type: .png)
        let image = PixelSize(width: 3000, height: 2000)
        let rect = SmartCropPlacement.place(aspect: 1, in: image, boxes: SubjectBoxes(subjects: [CGRect(x: 0.31, y: 0.4, width: 0.2, height: 0.2)]))
        #expect(OutputGeometry.croppedSize(source: image, crop: CropSpec(rect: rect)) == PixelSize(width: 2000, height: 2000))
        let job = ExportJob(source: url, recipe: EditRecipe(crop: CropSpec(rect: rect), resize: ResizeSpec(value: 1920)),
                            settings: ExportSettings(), destination: dir.appendingPathComponent("o.webp"))
        #expect(try ExportService().render(job).pixelSize == PixelSize(width: 1920, height: 1920))
    }

    @Test func crop16by9At1920() throws {
        let dir = try FixtureFactory.makeDirectory()
        let url = try FixtureFactory.write([FixtureFactory.photo(width: 3000, height: 2000)], to: dir.appendingPathComponent("p.png"), type: .png)
        let rect = CropMath.largestRect(aspect: 16.0 / 9, in: PixelSize(width: 3000, height: 2000))
        let recipe = EditRecipe(crop: CropSpec(rect: rect), resize: ResizeSpec(value: 1920))
        let job = ExportJob(source: url, recipe: recipe, settings: ExportSettings(), destination: dir.appendingPathComponent("o.webp"))
        #expect(try ExportService().render(job).pixelSize == PixelSize(width: 1920, height: 1080))
    }

    private func render(_ image: CGImage, _ crop: CropSpec) throws -> CGImage {
        let size = OutputGeometry.croppedSize(source: PixelSize(width: image.width, height: image.height), crop: crop)
        return try RenderPipeline.render(image, recipe: EditRecipe(crop: crop, sharpen: false), outputSize: size, flattenOnWhite: false)
    }

    private func pixel(_ image: CGImage, _ x: Int, _ y: Int) -> [UInt8] {
        let buffer = PixelBuffer(image)!
        let i = (y * image.width + x) * 4
        return Array(buffer.bytes[i..<i + 3])
    }
}
