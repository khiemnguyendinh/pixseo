import CoreGraphics
import Vision

/// Where the subject of a picture is: attention-based salient regions and faces.
/// Boxes are normalized with a top-left origin, in the image passed in.
public struct SubjectBoxes: Sendable, Equatable {
    public var subjects: [CGRect]
    public var faces: [CGRect]

    public init(subjects: [CGRect] = [], faces: [CGRect] = []) {
        self.subjects = subjects
        self.faces = faces
    }
}

public enum SaliencyAnalyzer {
    /// Runs Vision on a preview (≤ 1024 px is plenty, and keeps it under ~150 ms).
    /// Failures return no boxes, which makes crops fall back to the center.
    public static func analyze(_ image: CGImage) -> SubjectBoxes {
        let attention = VNGenerateAttentionBasedSaliencyImageRequest()
        let faces = VNDetectFaceRectanglesRequest()
        do {
            try VNImageRequestHandler(cgImage: image).perform([attention, faces])
        } catch {
            return SubjectBoxes()
        }
        let salient = (attention.results?.first?.salientObjects ?? []).map { topLeft($0.boundingBox) }
        let faceBoxes = (faces.results ?? []).map { topLeft($0.boundingBox) }
        return SubjectBoxes(subjects: salient, faces: faceBoxes)
    }

    /// Vision's origin is bottom-left.
    static func topLeft(_ r: CGRect) -> CGRect {
        CGRect(x: r.minX, y: 1 - r.maxY, width: r.width, height: r.height)
    }
}

/// Picks the crop frame for a ratio so the subject stays in it.
public enum SmartCropPlacement {
    /// Faces win over salient regions; each face box grows 15% upward so hair isn't cut.
    /// With no subject the frame is centered.
    public static func place(aspect: Double, in size: PixelSize, boxes: SubjectBoxes) -> CGRect {
        let faces = boxes.faces.map { face in
            CGRect(x: face.minX, y: max(0, face.minY - face.height * 0.15), width: face.width, height: face.height * 1.15)
        }
        let focus = union(faces) ?? union(boxes.subjects)
        let center = focus.map { CGPoint(x: $0.midX, y: $0.midY) } ?? CGPoint(x: 0.5, y: 0.5)
        return CropMath.largestRect(aspect: aspect, in: size, centeredOn: center)
    }

    private static func union(_ rects: [CGRect]) -> CGRect? {
        guard let first = rects.first else { return nil }
        return rects.dropFirst().reduce(first) { $0.union($1) }
    }
}
