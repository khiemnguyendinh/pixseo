import CoreGraphics
import Testing
@testable import PixSEOCore

struct OutputGeometryTests {
    private func size(_ w: Int, _ h: Int) -> PixelSize { PixelSize(width: w, height: h) }

    @Test func widthModeIsTheDefault() {
        #expect(OutputGeometry.outputSize(for: size(6000, 4000), resize: ResizeSpec(value: 1920)).size == size(1920, 1280))
        #expect(OutputGeometry.outputSize(for: size(3000, 4000), resize: ResizeSpec(value: 1080)).size == size(1080, 1440))
    }

    @Test func longEdgeAndHeightModes() {
        #expect(OutputGeometry.outputSize(for: size(3000, 4000), resize: ResizeSpec(mode: .longEdge, value: 1920)).size == size(1440, 1920))
        #expect(OutputGeometry.outputSize(for: size(6000, 4000), resize: ResizeSpec(mode: .height, value: 1080)).size == size(1620, 1080))
    }

    @Test func neverUpscales() {
        let result = OutputGeometry.outputSize(for: size(800, 600), resize: ResizeSpec(value: 1920))
        #expect(result.size == size(800, 600))
        #expect(result.notUpscaled)
        #expect(!OutputGeometry.outputSize(for: size(800, 600), resize: ResizeSpec()).notUpscaled)
    }

    @Test func cropAfterRotation() {
        // 6000×4000 turned once becomes 4000×6000; its right half is 2000×6000.
        let crop = CropSpec(rect: CGRect(x: 0.5, y: 0, width: 0.5, height: 1), quarterTurns: 1)
        #expect(OutputGeometry.croppedSize(source: size(6000, 4000), crop: crop) == size(2000, 6000))
    }

    @Test func ogPresetGivesExactly1200x630() {
        // 40:21 crop from a 6000×4000 photo, then width 1200.
        let rect = CGRect(x: 0, y: 0, width: 1, height: (6000.0 * 21 / 40) / 4000)
        let cropped = OutputGeometry.croppedSize(source: size(6000, 4000), crop: CropSpec(rect: rect))
        #expect(OutputGeometry.outputSize(for: cropped, resize: ResizeSpec(value: 1200)).size == size(1200, 630))
    }

    @Test func decodesAtTwiceTheNeededScaleOnly() {
        #expect(OutputGeometry.decodeLongEdge(source: size(6000, 4000), cropped: size(6000, 4000), output: size(1920, 1280)) == 3840)
        #expect(OutputGeometry.decodeLongEdge(source: size(6000, 4000), cropped: size(6000, 4000), output: size(6000, 4000)) == 6000)
    }
}
