import Foundation
import Observation
import PixSEOCore

/// Live "how big will the file be" estimate: encodes one job in the background 250 ms after the
/// last change, cancelling any estimate in flight, and keeps the bytes so saving with unchanged
/// settings writes them without encoding again.
@MainActor
@Observable
final class SizeEstimator {
    private(set) var output: RenderedOutput?
    private(set) var error: ExportError?
    private(set) var isEstimating = false
    /// The job the current `output`/`error` belongs to.
    private(set) var job: ExportJob?

    private let service: ExportService
    private var task: Task<Void, Never>?

    init(service: ExportService) {
        self.service = service
    }

    /// Estimate key: `source` + recipe + settings with a fixed destination, so it compares by settings only.
    static func key(source: URL, recipe: EditRecipe, settings: ExportSettings) -> ExportJob {
        ExportJob(source: source, recipe: recipe, settings: settings, destination: URL(fileURLWithPath: "/dev/null"))
    }

    func schedule(_ job: ExportJob?) {
        task?.cancel()
        guard let job else { return }
        isEstimating = true
        let service = self.service
        task = Task {
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            let result = await Task.detached(priority: .userInitiated) { () -> Result<RenderedOutput, ExportError> in
                do { return .success(try service.render(job)) }
                catch let error as ExportError { return .failure(error) }
                catch { return .failure(.encodeFailed) }
            }.value
            guard !Task.isCancelled else { return }
            switch result {
            case .success(let output): self.output = output; self.error = nil
            case .failure(let error): self.output = nil; self.error = error
            }
            self.job = job
            isEstimating = false
        }
    }

    /// The encoded bytes, only if they were made for exactly `job`.
    func reusable(for job: ExportJob?) -> RenderedOutput? {
        job != nil && job == self.job ? output : nil
    }

    /// Warnings from the last estimate, only if it matches `job` (older ones would mislead).
    func warnings(for job: ExportJob?) -> [ExportWarning] {
        job != nil && job == self.job ? output?.warnings ?? [] : []
    }

    func cancel() {
        task?.cancel()
    }
}
