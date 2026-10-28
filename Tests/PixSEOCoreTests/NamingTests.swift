import Foundation
import Testing
@testable import PixSEOCore

struct SEOSluggerTests {
    @Test(arguments: [
        ("Khai Giảng K15", "khai-giang-k15"),
        ("ĐÀO TẠO Spa & Thẩm mỹ", "dao-tao-spa-tham-my"),
        ("  --Hello__World--  ", "hello-world"),
        ("🔥🔥", "anh"),
        ("Lễ tốt nghiệp 2026", "le-tot-nghiep-2026"),
        ("Trường Trung cấp Quốc tế Phoenix", "truong-trung-cap-quoc-te-phoenix"),
    ])
    func slugifies(_ input: String, _ expected: String) {
        #expect(SEOSlugger.slugify(input) == expected)
    }

    @Test func decomposedInputMatchesPrecomposed() {
        let text = "Khai Giảng K15 Đặc biệt"
        #expect(SEOSlugger.slugify(text.decomposedStringWithCanonicalMapping) == SEOSlugger.slugify(text.precomposedStringWithCanonicalMapping))
    }

    @Test func truncatesAtWordBoundary() {
        let slug = SEOSlugger.slugify(String(repeating: "khai giang ", count: 12))
        #expect(slug.count <= 60)
        #expect(!slug.hasSuffix("-"))
        #expect(slug.split(separator: "-").allSatisfy { $0 == "khai" || $0 == "giang" })
    }

    @Test func stripsTypedImageExtension() {
        #expect(SEOSlugger.stripImageExtension("banner.webp ") == "banner")
        #expect(SEOSlugger.stripImageExtension("v1.2 final") == "v1.2 final")
    }
}

struct OutputFileNamerTests {
    private let dir = URL(fileURLWithPath: "/tmp/pixseo-naming")
    private let size1920 = PixelSize(width: 1920, height: 1080)

    private func namer(existing: Set<String> = []) -> OutputFileNamer {
        OutputFileNamer(fileExists: { existing.contains($0.lastPathComponent) })
    }

    @Test func userExample() {
        #expect(namer().preview(input: "Khai Giảng K15.png", outputSize: size1920, fileExtension: "webp", in: dir) == "khai-giang-k15-1920.webp")
    }

    @Test func doesNotRepeatSizeSuffix() {
        #expect(namer().preview(input: "banner-1920", outputSize: size1920, fileExtension: "webp", in: dir) == "banner-1920.webp")
        #expect(namer().preview(input: "banner-1920px", outputSize: size1920, fileExtension: "webp", in: dir) == "banner-1920.webp")
        #expect(namer().preview(input: "banner-1920x1080", outputSize: size1920, fileExtension: "webp", in: dir) == "banner-1920.webp")
    }

    @Test func suffixUsesActualOutputWidth() {
        #expect(namer().preview(input: "nho", outputSize: PixelSize(width: 1280, height: 720), fileExtension: "jpg", in: dir) == "nho-1280.jpg")
        let dims = OutputFileNamer(suffix: .dimensions, fileExists: { _ in false })
        #expect(dims.preview(input: "a b", outputSize: size1920, fileExtension: "png", in: dir) == "a-b-1920x1080.png")
    }

    @Test func avoidsExistingFiles() {
        let n = namer(existing: ["a-1920.webp", "a-1920-2.webp"])
        #expect(n.preview(input: "a", outputSize: size1920, fileExtension: "webp", in: dir) == "a-1920-3.webp")
    }

    @Test func sharedBatchIsNumberedAndPadded() {
        let items = (0..<12).map { _ in OutputFileNamer.Item(input: "IMG_1", outputSize: size1920, directory: dir) }
        let names = namer().plan(items, mode: .shared("Khai giảng"), fileExtension: "webp").map(\.lastPathComponent)
        #expect(names.first == "khai-giang-01-1920.webp")
        #expect(names.last == "khai-giang-12-1920.webp")
        let many = (0..<120).map { _ in OutputFileNamer.Item(input: "x", outputSize: size1920, directory: dir) }
        #expect(namer().plan(many, mode: .shared("le"), fileExtension: "webp").first?.lastPathComponent == "le-001-1920.webp")
    }

    @Test func singleImageSharedModeHasNoNumber() {
        let item = OutputFileNamer.Item(input: "x", outputSize: size1920, directory: dir)
        #expect(namer().plan([item], mode: .shared("le"), fileExtension: "webp").first?.lastPathComponent == "le-1920.webp")
    }

    @Test func sameSlugInsideOneBatchGetsSuffix() {
        let items = ["Ảnh 1.png", "anh-1.jpg"].map { OutputFileNamer.Item(input: $0, outputSize: size1920, directory: dir) }
        let names = namer().plan(items, mode: .individual, fileExtension: "webp").map(\.lastPathComponent)
        #expect(names == ["anh-1-1920.webp", "anh-1-1920-2.webp"])
    }
}

struct MeaninglessNameDetectorTests {
    @Test(arguments: [
        "IMG_4521.HEIC", "DSC00123.jpg", "z5678901234567_ab12cd34ef56ab78cd90.jpg",
        "Ảnh màn hình 2026-10-28 lúc 10.15.30.png", "Screenshot 2026-10-28 at 10.15.30.png",
        "ChatGPT Image Oct 28, 2026, 10_15_30 AM.png", "Gemini_Generated_Image_abc123.png",
        "received_1234567890.jpeg", "FB_IMG_1698000000000.jpg", "20261028_101530.jpg",
        "3f2504e0-4f89-11d3-9a0c-0305e82c3301.png", "unnamed (3).jpg", "a1.png",
    ])
    func flagsMeaningless(_ name: String) {
        #expect(MeaninglessNameDetector.isMeaningless(name))
    }

    @Test(arguments: ["khai-giang-k15.png", "Lễ tốt nghiệp 2026.jpg", "banner-tuyen-sinh-spa.webp", "logo kstudy.png"])
    func keepsMeaningful(_ name: String) {
        #expect(!MeaninglessNameDetector.isMeaningless(name))
    }
}
