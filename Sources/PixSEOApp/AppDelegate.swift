import AppKit
import PixSEOCore
import PixSEOShared

/// Wires the two ways requests reach PixSEO into `IntakeRouter`:
/// `pixseo://` URLs from the Finder extension, and files opened or dropped on the app.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let service = ExportService()
    private lazy var runner = ExportRunner(service: service)
    private lazy var editors = EditorCoordinator(service: service, runner: runner)
    private lazy var quickSave = QuickSaveCoordinator(service: service, runner: runner, editors: editors)
    private lazy var router = IntakeRouter { [quickSave] intake in quickSave.handle(intake) }
    private lazy var settingsWindow = SingleWindowController(title: "Cài đặt PixSEO") { SettingsView() }
    private lazy var homeWindow = SingleWindowController(title: "PixSEO") { [weak self] in
        HomeView(onFiles: { urls in self?.openFiles(urls) }, onSettings: { self?.showSettings() })
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        // A dedicated handler (instead of application(_:open:)) keeps the Apple Event at hand,
        // which is needed to read the sender's PID and verify the request came from our extension.
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURL(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        MainMenu.install(settings: #selector(showSettings), target: self)
        router.appDidFinishLaunching()
        IdleQuitTimer.shared.start()
        // Core Image's one-time setup happens now, not on the user's first export.
        Task.detached(priority: .utility) { RenderPipeline.prewarm() }

        // Opened directly from Applications or Launchpad: show Home so the user can see the app
        // is alive, whether the Finder menu is enabled, and drop images in.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(600))
            if !router.hasReceivedRequest { homeWindow.show() }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        homeWindow.show()
        return false
    }

    /// Files dropped on the app icon or chosen through "Open With".
    func application(_ application: NSApplication, open urls: [URL]) {
        openFiles(urls)
    }

    private func openFiles(_ urls: [URL]) {
        router.receive(IntakeRequest(action: .open, files: urls.filter(\.isFileURL)), trusted: true)
    }

    @objc private func showSettings() {
        settingsWindow.show()
    }

    @objc private func handleGetURL(_ event: NSAppleEventDescriptor, withReplyEvent reply: NSAppleEventDescriptor) {
        guard let raw = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: raw)
        else { return }
        router.receive(url: url, trusted: SenderVerifier.isOwnFinderExtension(event))
    }
}
