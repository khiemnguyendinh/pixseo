import AppKit

/// Quits PixSEO after a quiet period so it never lingers in memory. The Finder extension
/// relaunches it on the next right-click.
///
/// "Quiet" means no visible window or panel and no export running.
@MainActor
final class IdleQuitTimer {
    static let shared = IdleQuitTimer()

    private var lastActivity = Date()
    private var activeWork = 0
    private var timer: Timer?

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            MainActor.assumeIsolated { IdleQuitTimer.shared.check() }
        }
    }

    func noteActivity() {
        lastActivity = Date()
    }

    /// Wrap long work (batch exports) so the app can't quit in the middle of it.
    func beginWork() {
        activeWork += 1
        noteActivity()
    }

    func endWork() {
        activeWork = max(0, activeWork - 1)
        noteActivity()
    }

    private func check() {
        let minutes = SettingsStore.shared.preferences.idleQuitMinutes
        guard minutes > 0, activeWork == 0, !NSApp.windows.contains(where: \.isVisible) else {
            if NSApp.windows.contains(where: \.isVisible) { noteActivity() }
            return
        }
        if Date().timeIntervalSince(lastActivity) >= Double(minutes) * 60 {
            NSApp.terminate(nil)
        }
    }
}
