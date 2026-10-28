import CoreGraphics
import Testing
@testable import PixSEOCore

struct SmartCropPlacementTests {
    private let size = PixelSize(width: 6000, height: 4000)

    @Test func keepsFaceInsidePortraitCrop() {
        let face = CGRect(x: 0.75, y: 0.2, width: 0.1, height: 0.15)
        let rect = SmartCropPlacement.place(aspect: 4.0 / 5, in: size, boxes: SubjectBoxes(subjects: [CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2)], faces: [face]))
        #expect(rect.contains(face), "faces win over other salient regions")
    }

    @Test func faceNearEdgeClampsFrame() {
        let face = CGRect(x: 0.92, y: 0.4, width: 0.07, height: 0.1)
        let rect = SmartCropPlacement.place(aspect: 1, in: size, boxes: SubjectBoxes(faces: [face]))
        #expect(abs(rect.maxX - 1) < 1e-9)
        #expect(rect.contains(face))
    }

    @Test func centersWithoutSubject() {
        let rect = SmartCropPlacement.place(aspect: 1, in: size, boxes: SubjectBoxes())
        #expect(abs(rect.midX - 0.5) < 1e-9 && abs(rect.midY - 0.5) < 1e-9)
    }

    @Test func canvasMappingRoundTrip() {
        let mapping = CanvasMapping(imageSize: CGSize(width: 2048, height: 1365), viewSize: CGSize(width: 900, height: 600), inset: 16)
        #expect(mapping.imageFrame.width <= 868.0001 && mapping.imageFrame.height <= 568.0001)
        for point in [CGPoint(x: 0, y: 0), CGPoint(x: 0.33, y: 0.71), CGPoint(x: 1, y: 1)] {
            let back = mapping.unitPoint(mapping.viewPoint(point))
            // Within half a preview pixel.
            #expect(abs(back.x - point.x) * 2048 < 0.5 && abs(back.y - point.y) * 1365 < 0.5)
        }
    }
}
