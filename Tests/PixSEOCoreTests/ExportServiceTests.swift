import CoreGraphics
import CryptoKit
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import PixSEOCore

struct ExportServiceTests {
    let service = ExportService()

    private func job(_ source: URL, width: Int? = 1920, format: OutputFormat = .webp, quality: Double = 0.8,
                     target: Int? = nil, ppi: Int = 72, crop: CropSpec? = nil) -> ExportJob {
        ExportJob(source: source, recipe: EditRecipe(crop: crop, resize: ResizeSpec(value: width)),
                  settings: ExportSettings(format: format, quality: quality, targetBytes: target, ppi: ppi),
                  destination: source.deletingLastPathComponent().appendingPathComponent("out-\(UUID().uuidString).\(format.fileExtension)"))
    }

    @Test(arguments: OutputFormat.allCases)
    func writesEveryFormatAtTheRequestedWidth(_ format: OutputFormat) throws {
        let dir = try FixtureFactory.makeDirectory()
        let source = try FixtureFactory.write([FixtureFactory.photo(width: 3000, height: 2000)], to: dir.appendingPathComponent("a.png"), type: .png)
        let result = try service.export(job(source, format: format))
        let decoded = FixtureFactory.decode(result.url)
        #expect(UTType(decoded.type)?.conforms(to: format.utType) == true)
        #expect(decoded.image.width == 1920 && decoded.image.height == 1280)
        #expect(result.pixelSize == PixelSize(width: 1920, height: 1280))
    }

    @Test func appliesExifOrientation() throws {
        let dir = try FixtureFactory.makeDirectory()
        let source = try FixtureFactory.write([FixtureFactory.photo(width: 400, height: 300)], to: dir.appendingPathComponent("o.jpg"),
                                              type: .jpeg, properties: [kCGImagePropertyOrientation: 6])
        let result = try service.export(job(source, width: nil, format: .png))
        let image = FixtureFactory.decode(result.url).image
        #expect(image.width == 300 && image.height == 400)
        // Orientation 6 turns the image clockwise: the stored top-left marker ends up top-right.
        let marker = FixtureFactory.pixel(image, x: image.width - 5, y: 5)
        #expect(marker[0] > 200 && marker[1] < 60)
    }

    @Test func writesPPIForJPEGAndPNGOnly() throws {
        let dir = try FixtureFactory.makeDirectory()
        let source = try FixtureFactory.write([FixtureFactory.photo(width: 800, height: 600)], to: dir.appendingPathComponent("p.png"), type: .png)
        let jpeg = try service.export(job(source, format: .jpeg, ppi: 96))
        #expect(FixtureFactory.properties(of: jpeg.url)[kCGImagePropertyDPIWidth] as? Int == 96)
        let png = try service.export(job(source, format: .png, ppi: 72))
        #expect(FixtureFactory.properties(of: png.url)[kCGImagePropertyDPIWidth] as? Int == 72)
        #expect(try service.export(job(source, format: .webp)).warnings.contains(.ppiIgnored))
    }

    @Test func stripsGPSAndExif() throws {
        let dir = try FixtureFactory.makeDirectory()
        let source = try FixtureFactory.write([FixtureFactory.photo(width: 800, height: 600)], to: dir.appendingPathComponent("gps.jpg"),
                                              type: .jpeg, properties: FixtureFactory.gpsAndExif)
        #expect(FixtureFactory.properties(of: source)[kCGImagePropertyGPSDictionary] != nil)
        for format in [OutputFormat.jpeg, .webp] {
            let props = FixtureFactory.properties(of: try service.export(job(source, format: format)).url)
            #expect(props[kCGImagePropertyGPSDictionary] == nil)
            let exif = props[kCGImagePropertyExifDictionary] as? [CFString: Any]
            #expect(exif?[kCGImagePropertyExifLensModel] == nil)
        }
    }

    @Test func convertsDisplayP3ToSRGB() throws {
        let dir = try FixtureFactory.makeDirectory()
        let p3 = FixtureFactory.photo(width: 600, height: 400, colorSpace: CGColorSpace(name: CGColorSpace.displayP3)!)
        let source = try FixtureFactory.write([p3], to: dir.appendingPathComponent("p3.png"), type: .png)
        let image = FixtureFactory.decode(try service.export(job(source, format: .png)).url).image
        #expect(image.colorSpace?.name == CGColorSpace.sRGB)
    }

    @Test func flattensTransparencyForJPEG() throws {
        let dir = try FixtureFactory.makeDirectory()
        let source = try FixtureFactory.write([FixtureFactory.photo(width: 600, height: 400, alpha: true)], to: dir.appendingPathComponent("t.png"), type: .png)
        let result = try service.export(job(source, format: .jpeg))
        #expect(result.warnings.contains(.alphaFlattened))
        let corner = FixtureFactory.pixel(FixtureFactory.decode(result.url).image, x: 590, y: 390)
        #expect(corner.prefix(3).allSatisfy { $0 > 245 })
        // WebP keeps transparency.
        let webp = FixtureFactory.decode(try service.export(job(source, format: .webp)).url).image
        #expect(FixtureFactory.pixel(webp, x: 590, y: 390)[3] < 10)
    }

    @Test func keepsAnimationForGIFAndWarnsOtherwise() throws {
        let dir = try FixtureFactory.makeDirectory()
        let frames = (0..<10).map { _ in FixtureFactory.photo(width: 400, height: 300) }
        let delay: [CFString: Any] = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 0.2]]
        let source = try FixtureFactory.write(frames, to: dir.appendingPathComponent("anim.gif"), type: .gif, properties: delay)
        let gif = try service.export(job(source, width: 200, format: .gif))
        #expect(FixtureFactory.decode(gif.url).frames == 10)
        let gifDict = FixtureFactory.properties(of: gif.url, index: 3)[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        #expect(abs((gifDict?[kCGImagePropertyGIFDelayTime] as? Double ?? 0) - 0.2) < 0.01)
        #expect(try service.export(job(source, width: 200, format: .webp)).warnings.contains(.animationDropped))
    }

    @Test func meetsByteLimitOrSaysWhy() throws {
        let dir = try FixtureFactory.makeDirectory()
        let source = try FixtureFactory.write([FixtureFactory.photo(width: 4000, height: 3000)], to: dir.appendingPathComponent("big.png"), type: .png)
        let unlimited = try service.render(job(source, quality: 0.92))
        let target = unlimited.data.count * 2 / 3
        let limited = try service.render(job(source, quality: 0.92, target: target))
        #expect(limited.data.count <= target)
        #expect(limited.quality < 0.92)
        let impossible = try service.render(job(source, target: 2_000))
        #expect(impossible.warnings.contains(.targetNotMet(suggestedWidth: 1600)))
    }

    @Test func neverOverwritesAndNeverTouchesTheSource() throws {
        let dir = try FixtureFactory.makeDirectory()
        let source = try FixtureFactory.write([FixtureFactory.photo(width: 800, height: 600)], to: dir.appendingPathComponent("s.jpg"), type: .jpeg)
        let before = SHA256.hash(data: try Data(contentsOf: source))
        var existing = job(source)
        try Data("keep me".utf8).write(to: existing.destination)
        #expect(throws: ExportError.destinationExists(existing.destination)) { try service.export(existing) }
        #expect(try String(contentsOf: existing.destination, encoding: .utf8) == "keep me")
        existing.destination = source
        #expect(throws: ExportError.destinationExists(source)) { try service.export(existing) }
        #expect(SHA256.hash(data: try Data(contentsOf: source)) == before)
        let leftovers = try FileManager.default.contentsOfDirectory(atPath: dir.path).filter { $0.hasSuffix(".pixseo-tmp") }
        #expect(leftovers.isEmpty)
    }

    @Test func warnsWhenOutputIsBiggerThanSource() throws {
        let dir = try FixtureFactory.makeDirectory()
        let image = FixtureFactory.photo(width: 1200, height: 800)
        let source = try FixtureFactory.write([image], to: dir.appendingPathComponent("tiny.jpg"), type: .jpeg,
                                              properties: [kCGImageDestinationLossyCompressionQuality: 0.3])
        let result = try service.render(job(source, width: nil, format: .jpeg, quality: 0.95))
        #expect(result.warnings.contains { if case .largerThanSource = $0 { true } else { false } })
    }

    @Test func refusesWebPBeyondItsDimensionLimit() throws {
        let dir = try FixtureFactory.makeDirectory()
        let source = try FixtureFactory.write([FixtureFactory.photo(width: 20000, height: 40)], to: dir.appendingPathComponent("pano.png"), type: .png)
        #expect(throws: ExportError.dimensionTooLarge(max: 16383)) { try service.render(job(source, width: nil)) }
    }

    @Test func classifiesPhotosAndGraphics() throws {
        let dir = try FixtureFactory.makeDirectory()
        let photo = try FixtureFactory.write([FixtureFactory.photo(width: 600, height: 400)], to: dir.appendingPathComponent("ph.png"), type: .png)
        #expect(try ImageSourceReader.readInfo(photo).contentKind == .photo)
        let logo = try FixtureFactory.write([FixtureFactory.photo(width: 600, height: 400, alpha: true)], to: dir.appendingPathComponent("lg.png"), type: .png)
        #expect(try ImageSourceReader.readInfo(logo).contentKind == .graphic)
    }

    @Test func batchKeepsOrderAndReportsFailures() async throws {
        let dir = try FixtureFactory.makeDirectory()
        let good = try FixtureFactory.write([FixtureFactory.photo(width: 800, height: 600)], to: dir.appendingPathComponent("g.png"), type: .png)
        let jobs = [job(good), job(dir.appendingPathComponent("missing.png")), job(good)]
        let results = await service.exportBatch(jobs)
        #expect(results.count == 3)
        #expect((try? results[0].get()) != nil && (try? results[2].get()) != nil)
        #expect(results[1] == .failure(.unreadable) || { if case .failure = results[1] { true } else { false } }())
    }

    @Test func largePhotoIsFast() throws {
        let dir = try FixtureFactory.makeDirectory()
        let source = try FixtureFactory.write([FixtureFactory.photo(width: 6000, height: 4000)], to: dir.appendingPathComponent("24mp.jpg"),
                                              type: .jpeg, properties: [kCGImageDestinationLossyCompressionQuality: 0.9])
        // First run pays one-time Core Image/Metal setup; the app keeps that warm afterwards.
        let cold = ContinuousClock.now
        _ = try ExportService().export(job(source))
        let coldElapsed = ContinuousClock.now - cold
        let start = ContinuousClock.now
        let result = try ExportService().export(job(source))
        let elapsed = ContinuousClock.now - start
        print("PERF 24MP JPEG -> WebP 1920: cold \(coldElapsed), warm \(elapsed), \(result.sourceBytes / 1024) KB -> \(result.bytes / 1024) KB")
        // Debug builds compile libwebp at -O0 and are several times slower; the budget applies to
        // release builds (scripts/test.sh -c release -Xswiftc -enable-testing --filter largePhotoIsFast).
        #if !DEBUG
        #expect(elapsed < .milliseconds(1500))
        #endif
    }
}

extension Result where Success == ExportResult, Failure == ExportError {
    static func == (lhs: Self, rhs: Self) -> Bool {
        if case .failure(let l) = lhs, case .failure(let r) = rhs { return l == r }
        return false
    }
}
