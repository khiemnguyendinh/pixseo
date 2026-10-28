import AppKit
import CoreGraphics
import CoreText
import Foundation
import Testing
@testable import PixSEOCore

struct SmartSEOTests {
    /// Banner with Vietnamese text drawn by CoreText.
    private func banner(_ title: String, subtitle: String) -> CGImage {
        let (w, h) = (1200, 400)
        let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.setFillColor(CGColor(srgbRed: 0.1, green: 0.2, blue: 0.6, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        func draw(_ text: String, size: CGFloat, y: CGFloat) {
            let attributes: [NSAttributedString.Key: Any] = [.font: CTFontCreateWithName("Helvetica-Bold" as CFString, size, nil), .foregroundColor: NSColor.white]
            ctx.textPosition = CGPoint(x: 80, y: y)
            CTLineDraw(CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attributes)), ctx)
        }
        draw(title, size: 90, y: 220)
        draw(subtitle, size: 44, y: 120)
        return ctx.makeImage()!
    }

    @Test func bannerTitleBecomesSlug() {
        let analysis = ContentAnalyzer.analyze(banner("KHAI GIẢNG K15", subtitle: "Khóa học Ứng dụng AI cho Marketing"))
        let suggestion = HeuristicNameSuggester.suggest(analysis: analysis)
        #expect(suggestion?.slug.hasPrefix("khai-giang-k15") == true, "got \(suggestion?.slug ?? "nil")")
        #expect(suggestion?.source == .text)
    }

    @Test func customWordsKeepAI() {
        let analysis = ContentAnalyzer.analyze(banner("KHÓA HỌC AI", subtitle: "Marketing"))
        #expect(analysis.lines.contains { $0.text.contains("AI") }, "\(analysis.lines.map(\.text))")
    }

    @Test func titleValidation() {
        #expect(NameSuggestion.validated(title: "Khai giảng K15 khóa AI", altText: nil, source: .onDevice)?.slug == "khai-giang-k15-khoa-ai")
        #expect(NameSuggestion.validated(title: "một hai ba bốn năm sáu bảy tám chín mười mười một mười hai", altText: nil, source: .onDevice) == nil)
        #expect(NameSuggestion.validated(title: "IMG 4521", altText: nil, source: .onDevice) == nil)
        #expect(NameSuggestion.validated(title: "  ", altText: nil, source: .onDevice) == nil)
    }

    @Test func altIsTrimmedAtWordBoundary() {
        let long = String(repeating: "học viên tham gia buổi khai giảng ", count: 8)
        let alt = NameSuggestion.trimAlt(long)
        #expect(alt.count <= 125)
        #expect(long.hasPrefix(alt))
        #expect(!alt.hasSuffix(" "))
        #expect(NameSuggestion.trimAlt("Hình ảnh của học viên lớp K15") == "Học viên lớp K15")
    }

    @Test func sentenceCaseKeepsCodes() {
        #expect(HeuristicNameSuggester.sentenceCase("KHAI GIẢNG K15 KHÓA AI") == "Khai giảng K15 khóa AI")
        #expect(HeuristicNameSuggester.sentenceCase("Lễ khai giảng") == "Lễ khai giảng")
    }

    @Test func labelsTranslate() {
        let suggestion = HeuristicNameSuggester.suggest(analysis: ContentAnalysis(labels: ["crowd", "auditorium", "unknown_thing"]))
        #expect(suggestion?.slug == "dam-dong-hoi-truong")
    }

    @Test func checklistThresholds() {
        func check(bytes: Int, edge: Int) -> SEOChecklist {
            SEOChecklist(bytes: bytes, outputSize: PixelSize(width: edge, height: edge / 2), slug: "khai-giang-k15",
                         format: .webp, contentKind: .photo, frameCount: 1, hasAltText: true)
        }
        #expect(check(bytes: 200 * 1024, edge: 2560).worst == .good)
        #expect(check(bytes: 200 * 1024 + 1, edge: 2560).worst == .fair)
        #expect(check(bytes: 500 * 1024 + 1, edge: 2560).worst == .poor)
        #expect(check(bytes: 1000, edge: 2561).worst == .fair)
        #expect(check(bytes: 1000, edge: 3841).worst == .poor)
        let messy = SEOChecklist(bytes: 1000, outputSize: nil, slug: "img-4521", format: .gif, contentKind: .photo, frameCount: 1, hasAltText: false)
        #expect(messy.issues.count == 3)
    }
}
