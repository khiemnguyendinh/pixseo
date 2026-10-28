import Foundation
import Testing
@testable import PixSEOShared

struct IntakeRequestTests {
    private func roundTrip(_ request: IntakeRequest) throws -> IntakeRequest {
        let urls = request.makeURLs()
        #expect(urls.count == 1)
        return try #require(IntakeRequest(url: urls[0]))
    }

    @Test func roundTripKeepsActionWidthAndPaths() throws {
        let files = [
            "/Users/a/Desktop/Khai Giảng K15.png",
            "/Users/a/Ảnh & tài liệu/a=b+c?#%.jpg",
            "/Volumes/USB/🔥 banner.webp",
        ].map { URL(fileURLWithPath: $0) }
        let decoded = try roundTrip(IntakeRequest(action: .resize, width: 1920, files: files))
        #expect(decoded.action == .resize)
        #expect(decoded.width == 1920)
        #expect(decoded.files.map(\.path) == files.map(\.path))
    }

    @Test func decomposedVietnameseNamesSurviveUnchanged() throws {
        let nfd = "/tmp/" + "Khai Giảng".decomposedStringWithCanonicalMapping + ".png"
        let decoded = try roundTrip(IntakeRequest(action: .crop, files: [URL(fileURLWithPath: nfd)]))
        #expect(decoded.files.first?.path.unicodeScalars.elementsEqual(nfd.unicodeScalars) == true)
        #expect(decoded.width == nil)
    }

    @Test func largeSelectionsAreChunkedAndReassembled() throws {
        let files = (0..<120).map { URL(fileURLWithPath: "/tmp/img-\($0).jpg") }
        let urls = IntakeRequest(action: .watermark, files: files).makeURLs(batchID: "b1")
        #expect(urls.count == 3)

        var assembler = IntakeBatchAssembler()
        let parts = urls.compactMap(IntakeRequest.init(url:))
        #expect(assembler.accept(parts[2]) == nil)
        #expect(assembler.accept(parts[0]) == nil)
        let last = assembler.accept(parts[1])
        let merged = try #require(last)
        #expect(merged.files == files)
        #expect(merged.chunk == nil)
        #expect(!assembler.hasPending)
    }

    @Test func expiredBatchesReleaseWhatArrived() {
        let files = (0..<60).map { URL(fileURLWithPath: "/tmp/\($0).png") }
        let parts = IntakeRequest(action: .resize, width: 1080, files: files)
            .makeURLs(batchID: "b2").compactMap(IntakeRequest.init(url:))
        var assembler = IntakeBatchAssembler()
        let start = Date()
        #expect(assembler.accept(parts[0], now: start) == nil)
        #expect(assembler.drainExpired(now: start.addingTimeInterval(1)).isEmpty)
        let released = assembler.drainExpired(now: start.addingTimeInterval(3))
        #expect(released.count == 1)
        #expect(released.first?.files.count == 50)
        #expect(released.first?.width == 1080)
    }

    @Test(arguments: [
        "https://run?a=resize&f=/tmp/a.jpg",
        "pixseo://other?a=resize&f=/tmp/a.jpg",
        "pixseo://run?a=delete&f=/tmp/a.jpg",
        "pixseo://run?a=resize&w=8&f=/tmp/a.jpg",
        "pixseo://run?a=resize&w=99999&f=/tmp/a.jpg",
        "pixseo://run?a=resize&w=abc&f=/tmp/a.jpg",
        "pixseo://run?a=resize&f=relative/a.jpg",
        "pixseo://run?a=resize&b=x&i=3&n=2&f=/tmp/a.jpg",
        "pixseo://run?a=resize&b=x&n=2&f=/tmp/a.jpg",
    ])
    func rejectsMalformedURLs(_ raw: String) throws {
        #expect(IntakeRequest(url: try #require(URL(string: raw))) == nil)
    }
}

struct SupportedImageTypesTests {
    @Test(arguments: ["a.jpg", "b.JPEG", "c.heic", "d.webp", "e.PSD", "f.avif"])
    func acceptsImages(_ name: String) {
        #expect(SupportedImageTypes.isImage(URL(fileURLWithPath: "/tmp/\(name)")))
    }

    @Test(arguments: ["a.svg", "b.pdf", "c.txt", "folder", "d.jpg.zip"])
    func rejectsOthers(_ name: String) {
        #expect(!SupportedImageTypes.isImage(URL(fileURLWithPath: "/tmp/\(name)")))
    }
}
