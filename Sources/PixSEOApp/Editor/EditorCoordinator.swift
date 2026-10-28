import AppKit
import PixSEOCore

/// Opens editor windows (from Quick Crop, Quick Watermark, ⌘E in the panel, or Home) and saves
/// their results through the shared export runner.
@MainActor
final class EditorCoordinator {
    private let service: ExportService
    private let runner: ExportRunner
    private var editors: [EditorWindowController] = []

    init(service: ExportService, runner: ExportRunner) {
        self.service = service
        self.runner = runner
    }

    /// - Parameters:
    ///   - options/naming: carried over from the Quick Save panel so nothing the user set is lost.
    ///   - watermark: starting watermark; `nil` uses the default preset (or the last one used).
    func open(files: [URL], tab: EditorTab, options: ExportOptions? = nil, naming: FileNaming? = nil, watermark: WatermarkSpec? = nil) {
        guard !files.isEmpty else { return }
        IdleQuitTimer.shared.noteActivity()
        let model = EditorViewModel(files: files, tab: tab,
                                    options: options.map(ExportOptions.init(copying:)) ?? ExportOptions(preferences: SettingsStore.shared.preferences),
                                    naming: naming, watermark: watermark, service: service)
        let controller = EditorWindowController(
            model: model,
            onSave: { [weak self] controller, keepOpen in self?.save(controller, keepOpen: keepOpen) },
            onClosed: { [weak self] controller in self?.editors.removeAll { $0 === controller } }
        )
        editors.append(controller)
        controller.show()
    }

    private func save(_ controller: EditorWindowController, keepOpen: Bool) {
        let model = controller.model
        guard model.canSave else { return }
        model.storePreferences()
        IdleQuitTimer.shared.beginWork()
        Task {
            let plan = await model.makePlan()
            let jobs = await Task.detached(priority: .userInitiated) { plan.makeJobs() }.value
            IdleQuitTimer.shared.endWork()
            let note = model.suggestions.copyAltIfWanted() ? "Alt text đã copy" : nil
            runner.run(jobs, reuse: plan.reusable, retry: plan.retry, note: note)
            if keepOpen { model.markSaved() } else { controller.close() }
        }
    }
}
