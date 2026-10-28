import AppKit
import PixSEOCore

/// Decides what each validated request opens: the Quick Save panel, the editor (Crop and
/// Watermark), or a direct export when the user turned off "ask for a name" and the request is
/// trusted (it came from our Finder extension).
@MainActor
final class QuickSaveCoordinator {
    private let service: ExportService
    private let runner: ExportRunner
    private let editors: EditorCoordinator
    private var panels: [QuickSavePanelController] = []

    init(service: ExportService, runner: ExportRunner, editors: EditorCoordinator) {
        self.service = service
        self.runner = runner
        self.editors = editors
    }

    func handle(_ intake: ResolvedIntake) {
        IdleQuitTimer.shared.noteActivity()
        guard !intake.images.isEmpty else {
            ToastCenter.shared.show(ToastModel(
                style: .failure, title: "Không có ảnh hợp lệ",
                detail: intake.skipped.isEmpty ? nil : "Bỏ qua \(intake.skipped.count) file không đọc được."
            ))
            return
        }

        let preferences = SettingsStore.shared.preferences
        switch intake.action {
        case .crop:
            editors.open(files: intake.images, tab: .crop)
        case .watermark:
            editors.open(files: intake.images, tab: .watermark)
        case .resize where intake.width != nil && intake.trusted && !preferences.askNameBeforeSave:
            exportDirectly(intake, width: intake.width ?? preferences.width, preferences: preferences)
        case .resize, .open:
            openPanel(for: intake, preferences: preferences)
        }
    }

    private func openPanel(for intake: ResolvedIntake, preferences: ExportPreferences) {
        let model = QuickSaveViewModel(intake: intake, preferences: preferences, service: service)
        let controller = QuickSavePanelController(
            model: model,
            onSave: { [weak self] controller in self?.save(model, from: controller) },
            onOpenEditor: { [weak self] controller in
                controller.close()
                self?.editors.open(files: model.files, tab: .resize, options: model.options, naming: model.naming, watermark: model.watermark)
            },
            onClose: { [weak self] controller in self?.panels.removeAll { $0 === controller } }
        )
        panels.append(controller)
        controller.show(offset: panels.count - 1)
        model.load()
    }

    private func save(_ model: QuickSaveViewModel, from controller: QuickSavePanelController) {
        guard model.canSave else { return }
        SettingsStore.shared.preferences = model.updatedPreferences()
        model.suggestions.cancel()
        let note = model.suggestions.copyAltIfWanted() ? "Alt text đã copy" : nil
        controller.close()
        // Planning reads every image's size, so it runs off the main thread for big batches.
        let plan = model.planInputs()
        Task {
            let jobs = await Task.detached(priority: .userInitiated) { plan.makeJobs() }.value
            runner.run(jobs, reuse: plan.reusable, retry: plan.retry, note: note)
        }
    }

    /// The width came from the Finder menu and the user doesn't want a panel: export with the
    /// remembered settings, the Quick Resize watermark, and each file's own SEO name.
    private func exportDirectly(_ intake: ResolvedIntake, width: Int, preferences: ExportPreferences) {
        let watermark = SettingsStore.shared.watermarkPresets.presets.first { $0.id == preferences.quickSaveWatermarkID }?.spec
        let recipe = EditRecipe(resize: ResizeSpec(mode: preferences.resizeMode, value: width), sharpen: preferences.sharpen, watermark: watermark)
        let settings = ExportSettings(format: preferences.format, quality: preferences.quality,
                                      targetBytes: preferences.targetKB.map { $0 * 1024 }, ppi: preferences.ppi)
        let plan = SavePlan(files: intake.images, mode: .individual, singleName: nil,
                            recipes: Array(repeating: recipe, count: intake.images.count), settings: settings,
                            suffix: preferences.sizeSuffix, reusable: nil)
        Task {
            let jobs = await Task.detached(priority: .userInitiated) { plan.makeJobs() }.value
            runner.run(jobs, retry: plan.retry)
        }
    }
}
