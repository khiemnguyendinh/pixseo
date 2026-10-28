import AppKit

/// PixSEO lives without a Dock icon, but while a real window (Editor, Settings, Home) is open
/// it shows in the Dock and ⌘Tab like a normal app, so the user can find it again.
@MainActor
final class ActivationPolicyManager {
    static let shared = ActivationPolicyManager()
    private var windows: Set<ObjectIdentifier> = []

    func opened(_ window: NSWindow) {
        windows.insert(ObjectIdentifier(window))
        if NSApp.activationPolicy() != .regular {
            NSApp.setActivationPolicy(.regular)
        }
        NSApp.activate()
    }

    func closed(_ window: NSWindow) {
        windows.remove(ObjectIdentifier(window))
        if windows.isEmpty {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
