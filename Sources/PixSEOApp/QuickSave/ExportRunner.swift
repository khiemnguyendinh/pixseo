import AppKit
import PixSEOCore

/// Runs export jobs and reports the outcome in a toast with "Show in Finder" and "Undo".
/// Shared by the Quick Save panel and the no-panel path from the Finder menu.
@MainActor
final class ExportRunner {
    /// A file PixSEO created, remembered so Undo only trashes it if nobody changed it since.
    private struct CreatedFile {
        let url: URL
        let modified: Date?
        let size: Int?

        init(_ url: URL) {
            self.url = url
            let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
            modified = values?.contentModificationDate
            size = values?.fileSize
        }

        var isUnchanged: Bool { CreatedFile(url).modified == modified && CreatedFile(url).size == size && modified != nil }
    }

    /// Rebuilds failed jobs so they save into a folder the user picked.
    typealias RetryPlanner = @MainActor (_ failed: [ExportJob], _ folder: URL) -> [ExportJob]

    private let service: ExportService

    init(service: ExportService) {
        self.service = service
    }

    /// `reuse`: an estimate already encoded for the single job, written without encoding again.
    /// `retry`: rebuilds the failed jobs for another folder after a permission error.
    /// `note`: appended to a successful result ("Alt text đã copy").
    func run(_ jobs: [ExportJob], reuse: RenderedOutput? = nil, retry: RetryPlanner? = nil, note: String? = nil) {
        guard !jobs.isEmpty else { return }
        IdleQuitTimer.shared.beginWork()
        let toast = ToastModel(style: .progress, title: jobs.count == 1 ? "Đang lưu…" : "Đang lưu 0/\(jobs.count)…")
        let service = self.service
        let work = Task.detached(priority: .userInitiated) { () -> [Result<ExportResult, ExportError>] in
            if jobs.count == 1 {
                do { return [.success(try service.export(jobs[0], reuse: reuse))] }
                catch let error as ExportError { return [.failure(error)] }
                catch { return [.failure(.encodeFailed)] }
            }
            return await service.exportBatch(jobs) { done, total in
                Task { @MainActor in toast.title = "Đang lưu \(done)/\(total)…" }
            }
        }
        toast.actions = [ToastAction(title: "Hủy") { work.cancel() }]
        // A single save is usually instant; only show progress for batches.
        if jobs.count > 1 { ToastCenter.shared.show(toast) }

        Task {
            let results = await work.value
            IdleQuitTimer.shared.endWork()
            report(results, jobs: jobs, toast: toast, retry: retry, note: note)
        }
    }

    private func report(_ results: [Result<ExportResult, ExportError>], jobs: [ExportJob], toast: ToastModel,
                        retry: RetryPlanner?, note: String?) {
        let successes = results.compactMap { try? $0.get() }
        let failures = zip(jobs, results).compactMap { job, result -> (ExportJob, ExportError)? in
            if case .failure(let error) = result { return (job, error) }
            return nil
        }
        let created = successes.map { CreatedFile($0.url) }
        let sourceBytes = successes.reduce(0) { $0 + $1.sourceBytes }
        let outputBytes = successes.reduce(0) { $0 + $1.bytes }

        if let only = successes.first, successes.count == 1, failures.isEmpty {
            toast.title = "Đã lưu \(only.url.lastPathComponent)"
            toast.detail = "\(UserFacingText.bytes(only.bytes)) (\(UserFacingText.savings(from: only.sourceBytes, to: only.bytes)))"
                + (firstAdvice(only.warnings).map { " · \($0)" } ?? "")
        } else if !successes.isEmpty {
            toast.title = failures.isEmpty ? "Đã lưu \(successes.count) ảnh" : "Đã lưu \(successes.count)/\(jobs.count) ảnh · \(failures.count) lỗi"
            toast.detail = "\(UserFacingText.bytes(sourceBytes)) → \(UserFacingText.bytes(outputBytes)) (\(UserFacingText.savings(from: sourceBytes, to: outputBytes)))"
                + (failures.first.map { " · \(UserFacingText.error($0.1))" } ?? "")
        } else {
            toast.title = jobs.count == 1 ? "Không lưu được ảnh" : "Không lưu được \(jobs.count) ảnh"
            toast.detail = failures.first.map { UserFacingText.error($0.1) }
        }
        toast.style = failures.isEmpty ? .success : successes.isEmpty ? .failure : .warning
        if let note, !successes.isEmpty { toast.detail = [toast.detail, note].compactMap { $0 }.joined(separator: " · ") }

        var actions: [ToastAction] = []
        if !created.isEmpty {
            actions.append(ToastAction(title: "Hiện trong Finder") {
                NSWorkspace.shared.activateFileViewerSelecting(created.map(\.url))
            })
            actions.append(ToastAction(title: "Hoàn tác") { [weak self, weak toast] in
                self?.undo(created)
                if let toast { ToastCenter.shared.dismiss(toast) }
            })
        }
        let denied = failures.filter { if case .permissionDenied = $0.1 { true } else { false } }.map(\.0)
        if let retry, !denied.isEmpty {
            actions.append(ToastAction(title: "Lưu vào thư mục khác…") { [weak self, weak toast] in
                if let toast { ToastCenter.shared.dismiss(toast) }
                guard let folder = Self.chooseFolder() else { return }
                self?.run(retry(denied, folder), retry: retry)
            })
        }
        toast.actions = actions
        if ToastCenter.shared.isShowing(toast) { ToastCenter.shared.finish(toast) } else { ToastCenter.shared.show(toast) }
    }

    /// Moves files PixSEO just created to the Trash, skipping any that were changed since.
    private func undo(_ files: [CreatedFile]) {
        let untouched = files.filter(\.isUnchanged).map(\.url)
        guard !untouched.isEmpty else { return }
        NSWorkspace.shared.recycle(untouched) { _, error in
            Task { @MainActor in
                ToastCenter.shared.show(ToastModel(
                    style: error == nil ? .success : .failure,
                    title: error == nil ? "Đã chuyển \(untouched.count) file vào Thùng rác" : "Không hoàn tác được"
                ))
            }
        }
    }

    private func firstAdvice(_ warnings: [ExportWarning]) -> String? {
        ExportAdvisor.advice(info: nil, format: .webp, width: nil, estimateWarnings: warnings).first.map(UserFacingText.advice)
    }

    private static func chooseFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = "Lưu vào đây"
        NSApp.activate()
        return panel.runModal() == .OK ? panel.url : nil
    }
}
