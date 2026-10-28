import Foundation
import ImageIO
import OSLog
import PixSEOShared

/// A request whose files have been checked and are ready for the UI.
struct ResolvedIntake {
    var action: IntakeAction
    var width: Int?
    var images: [URL]
    /// Files that are missing, are folders, can't be decoded, or exceed the per-request limit.
    var skipped: [URL]
    /// True for requests from our own Finder extension or files the user opened;
    /// only these may be exported without a confirmation panel.
    var trusted: Bool
}

/// Receives every request, joins split batches, validates files, and hands the result to the UI.
@MainActor
final class IntakeRouter {
    static let maxFiles = 500
    private static let batchTimeout: Duration = .milliseconds(2100)

    private let log = Logger(subsystem: "app.pixseo.mac", category: "intake")
    private let present: (ResolvedIntake) -> Void
    private var assembler = IntakeBatchAssembler()
    /// A split batch is trusted only if every chunk of it was.
    private var batchTrust: [String: Bool] = [:]
    private var isReady = false
    private var queued: [ResolvedIntake] = []
    private(set) var hasReceivedRequest = false

    init(present: @escaping (ResolvedIntake) -> Void) {
        self.present = present
    }

    /// Requests can arrive before launch finishes; they wait until the app is ready to show UI.
    func appDidFinishLaunching() {
        isReady = true
        queued.forEach(present)
        queued.removeAll()
    }

    func receive(url: URL, trusted: Bool) {
        hasReceivedRequest = true
        guard let request = IntakeRequest(url: url) else {
            log.error("Ignored malformed intake URL")
            return
        }
        if let chunk = request.chunk {
            batchTrust[chunk.batchID] = (batchTrust[chunk.batchID] ?? true) && trusted
        }
        if let complete = assembler.accept(request) {
            route(complete, trusted: request.chunk.flatMap { batchTrust.removeValue(forKey: $0.batchID) } ?? trusted)
        } else {
            scheduleDrain()
        }
    }

    func receive(_ request: IntakeRequest, trusted: Bool) {
        hasReceivedRequest = true
        route(request, trusted: trusted)
    }

    private func scheduleDrain() {
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: Self.batchTimeout)
            guard let self else { return }
            for request in assembler.drainExpired() {
                log.warning("Batch timed out; continuing with \(request.files.count) received files")
                route(request, trusted: false)
            }
            if !assembler.hasPending { batchTrust.removeAll() }
        }
    }

    private func route(_ request: IntakeRequest, trusted: Bool) {
        let intake = resolve(request, trusted: trusted)
        log.info("Intake \(intake.action.rawValue, privacy: .public):\(intake.images.count) images, \(intake.skipped.count) skipped, trusted=\(intake.trusted)")
        if isReady { present(intake) } else { queued.append(intake) }
    }

    private func resolve(_ request: IntakeRequest, trusted: Bool) -> ResolvedIntake {
        var seen = Set<String>()
        var images: [URL] = []
        var skipped: [URL] = []
        for url in request.files.map(\.standardizedFileURL) where seen.insert(url.path).inserted {
            if images.count < Self.maxFiles, Self.isReadableImage(url) {
                images.append(url)
            } else {
                skipped.append(url)
            }
        }
        return ResolvedIntake(action: request.action, width: request.width, images: images, skipped: skipped, trusted: trusted)
    }

    /// Checks the file really is an image ImageIO can decode, not just that its extension says so.
    private static func isReadableImage(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
              !isDirectory.boolValue,
              let source = CGImageSourceCreateWithURL(url as CFURL, nil)
        else { return false }
        return CGImageSourceGetCount(source) > 0
    }
}
