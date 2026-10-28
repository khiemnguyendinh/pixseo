import CoreGraphics
import Vision

/// What's in a picture, from Vision on the device: text lines, scene labels and faces.
public struct ContentAnalysis: Sendable, Equatable {
    public struct TextLine: Sendable, Equatable {
        public let text: String
        /// Box height as a fraction of the image height; bigger = more prominent (a banner title).
        public let height: Double

        public init(text: String, height: Double) {
            self.text = text
            self.height = height
        }
    }

    public var lines: [TextLine]
    /// Vision identifiers (English), most confident first.
    public var labels: [String]
    public var faceCount: Int

    public init(lines: [TextLine] = [], labels: [String] = [], faceCount: Int = 0) {
        self.lines = lines
        self.labels = labels
        self.faceCount = faceCount
    }
}

public enum ContentAnalyzer {
    /// Short uppercase words OCR tends to misread ("AI" → "Al").
    public static let defaultCustomWords = ["AI", "SEO", "CEO", "MC", "KOL", "KPI", "MBA", "IELTS", "TOEIC", "VIP"]

    /// Runs text recognition (Vietnamese + English), classification (top 5, confidence ≥ 0.3)
    /// and face detection. Pass a preview ≤ 1600 px. Errors give an empty analysis.
    public static func analyze(_ image: CGImage, customWords: [String] = []) -> ContentAnalysis {
        let text = VNRecognizeTextRequest()
        text.recognitionLevel = .accurate
        text.recognitionLanguages = ["vi-VT", "en-US"]
        text.usesLanguageCorrection = true
        text.customWords = defaultCustomWords + customWords
        let classify = VNClassifyImageRequest()
        let faces = VNDetectFaceRectanglesRequest()
        do {
            try VNImageRequestHandler(cgImage: image).perform([text, classify, faces])
        } catch {
            return ContentAnalysis()
        }
        let lines = (text.results ?? []).compactMap { observation -> ContentAnalysis.TextLine? in
            guard let candidate = observation.topCandidates(1).first, candidate.confidence >= 0.3 else { return nil }
            return ContentAnalysis.TextLine(text: candidate.string, height: observation.boundingBox.height)
        }
        let labels = (classify.results ?? []).filter { $0.confidence >= 0.3 }.prefix(5).map(\.identifier)
        return ContentAnalysis(lines: lines, labels: Array(labels), faceCount: faces.results?.count ?? 0)
    }

    /// Words from the brand context ("Kstudy Academy, AI") so OCR keeps their spelling.
    public static func words(fromBrandContext context: String) -> [String] {
        context.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init).filter { $0.count >= 2 }
    }
}
