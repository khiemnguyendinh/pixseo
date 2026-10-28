import CoreGraphics
import Foundation
import PixSEOShared

/// One image to export.
public struct ExportJob: Sendable, Hashable {
    public var source: URL
    public var recipe: EditRecipe
    public var settings: ExportSettings
    /// Usually planned by `OutputFileNamer`, next to the source.
    public var destination: URL

    public init(source: URL, recipe: EditRecipe, settings: ExportSettings, destination: URL) {
        self.source = source
        self.recipe = recipe
        self.settings = settings
        self.destination = destination
    }
}

/// Runs the whole pipeline: read → decode → render → encode (within a byte limit) → write.
///
/// Methods are synchronous and thread-safe; call them off the main thread.
/// `@unchecked Sendable`: the only stored state is an NSCache, which is thread-safe.
public final class ExportService: @unchecked Sendable {
    /// Decoded sources keyed by file, modification date and decode size, so changing quality or
    /// format in the UI re-encodes without decoding a large HEIC again.
    private let decodeCache = NSCache<NSString, DecodedImage>()

    public init() {
        decodeCache.countLimit = 4
    }

    /// Encodes without writing, for size estimates. Pass the result to `export(_:reuse:)` to
    /// save it without encoding twice.
    public func render(_ job: ExportJob) throws -> RenderedOutput {
        try ImageSourceReader.ensureDownloaded(job.source)
        let info = try ImageSourceReader.readInfo(job.source)
        let settings = job.settings
        let cropped = OutputGeometry.croppedSize(source: info.pixelSize, crop: job.recipe.crop)
        let (output, notUpscaled) = OutputGeometry.outputSize(for: cropped, resize: job.recipe.resize)
        guard output.width <= settings.format.maxDimension, output.height <= settings.format.maxDimension else {
            throw ExportError.dimensionTooLarge(max: settings.format.maxDimension)
        }

        var warnings: [ExportWarning] = []
        if notUpscaled { warnings.append(.notUpscaled(original: cropped)) }
        if !settings.format.supportsPPI { warnings.append(.ppiIgnored) }
        // Flattening an opaque image is harmless, so any alpha channel is flattened for JPEG;
        // the warning is only shown when something was actually see-through.
        let flatten = settings.format == .jpeg && info.hasAlpha
        if flatten, info.hasTransparency { warnings.append(.alphaFlattened) }
        let animated = info.frameCount > 1 && settings.format == .gif
        if info.frameCount > 1, settings.format != .gif { warnings.append(.animationDropped) }

        let decodeEdge = OutputGeometry.decodeLongEdge(source: info.pixelSize, cropped: cropped, output: output)
        let renderFrame = { (index: Int) throws -> CGImage in
            try Task.checkCancellation()
            let frame = index == 0
                ? try self.decoded(info, maxLongEdge: decodeEdge)
                : try ImageSourceReader.orientedImage(info.url, index: index, maxLongEdge: decodeEdge)
            return try RenderPipeline.render(frame, recipe: job.recipe, outputSize: output, flattenOnWhite: flatten)
        }

        var data: Data
        var quality = settings.quality
        if animated {
            data = try ImageIOEncoder.encodeAnimatedGIF(frameCount: info.frameCount, delays: info.frameDelays,
                                                        loopCount: info.loopCount, frame: renderFrame)
        } else {
            let image = try renderFrame(0)
            if settings.format.supportsQuality {
                let outcome = try TargetSizeOptimizer.encode(target: settings.targetBytes, maxQuality: settings.quality) { q in
                    try Self.encodeStill(image, settings: settings, quality: q)
                }
                data = outcome.data
                quality = outcome.quality
                if !outcome.met { warnings.append(.targetNotMet(suggestedWidth: SizePresets.nextSmaller(than: output.width))) }
            } else {
                data = try Self.encodeStill(image, settings: settings, quality: quality)
            }
        }
        if !settings.format.supportsQuality || animated, let target = settings.targetBytes, data.count > target {
            warnings.append(.targetNotMet(suggestedWidth: nil))
        }
        if info.byteCount > 0, data.count > info.byteCount {
            warnings.append(.largerThanSource(percent: (data.count - info.byteCount) * 100 / info.byteCount))
        }
        return RenderedOutput(data: data, pixelSize: output, sourceBytes: info.byteCount, quality: quality, warnings: warnings)
    }

    /// Writes the job's result. `reuse` must come from `render` of the same job.
    public func export(_ job: ExportJob, reuse: RenderedOutput? = nil) throws -> ExportResult {
        let rendered = try reuse ?? render(job)
        try Task.checkCancellation()
        try SafeFileWriter.write(rendered.data, to: job.destination)
        return ExportResult(url: job.destination, bytes: rendered.data.count, pixelSize: rendered.pixelSize,
                            sourceBytes: rendered.sourceBytes, warnings: rendered.warnings)
    }

    /// Exports several images, `concurrency` at a time, results in input order.
    public func exportBatch(
        _ jobs: [ExportJob], concurrency: Int = 3, progress: (@Sendable (_ done: Int, _ total: Int) -> Void)? = nil
    ) async -> [Result<ExportResult, ExportError>] {
        var results = [Result<ExportResult, ExportError>?](repeating: nil, count: jobs.count)
        await withTaskGroup(of: (Int, Result<ExportResult, ExportError>).self) { group in
            var next = 0
            var done = 0
            func addNext() {
                guard next < jobs.count else { return }
                let index = next
                next += 1
                group.addTask { [self] in (index, Self.capture { try autoreleasepool { try self.export(jobs[index]) } }) }
            }
            for _ in 0..<min(max(concurrency, 1), jobs.count) { addNext() }
            for await (index, result) in group {
                results[index] = result
                done += 1
                progress?(done, jobs.count)
                if !Task.isCancelled { addNext() }
            }
        }
        return results.map { $0 ?? .failure(.cancelled) }
    }

    private static func capture(_ work: () throws -> ExportResult) -> Result<ExportResult, ExportError> {
        do { return .success(try work()) }
        catch let error as ExportError { return .failure(error) }
        catch is CancellationError { return .failure(.cancelled) }
        catch { return .failure(.encodeFailed) }
    }

    private static func encodeStill(_ image: CGImage, settings: ExportSettings, quality: Double) throws -> Data {
        settings.format == .webp
            ? try WebPEncoder.encode(image, quality: quality, keepAlpha: true)
            : try ImageIOEncoder.encodeStill(image, format: settings.format, quality: quality, ppi: settings.ppi)
    }

    private func decoded(_ info: SourceImageInfo, maxLongEdge: Int) throws -> CGImage {
        let modified = (try? info.url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate)?.timeIntervalSince1970 ?? 0
        let key = "\(info.url.path)|\(modified)|\(maxLongEdge)" as NSString
        if let cached = decodeCache.object(forKey: key) { return cached.image }
        let image = try ImageSourceReader.orientedImage(info.url, maxLongEdge: maxLongEdge)
        decodeCache.setObject(DecodedImage(image), forKey: key)
        return image
    }
}

/// NSCache needs a class value.
final class DecodedImage {
    let image: CGImage
    init(_ image: CGImage) { self.image = image }
}
