import AppKit
import SwiftUI

/// A normal, resizable editor window. While it is open PixSEO shows in the Dock and ⌘Tab.
/// Closing with unsaved edits asks first.
@MainActor
final class EditorWindowController: NSObject, NSWindowDelegate {
    let model: EditorViewModel
    private let window: NSWindow
    private let onClosed: (EditorWindowController) -> Void

    init(model: EditorViewModel, onSave: @escaping (EditorWindowController, Bool) -> Void,
         onClosed: @escaping (EditorWindowController) -> Void) {
        self.model = model
        self.onClosed = onClosed
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1180, height: 780),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        super.init()
        window.title = "PixSEO Editor"
        window.isReleasedWhenClosed = false
        window.contentMinSize = NSSize(width: 900, height: 600)
        window.delegate = self
        window.contentView = NSHostingView(rootView: EditorView(
            model: model,
            onSave: { [weak self] keepOpen in if let self { onSave(self, keepOpen) } },
            onClose: { [weak self] in self?.window.performClose(nil) }
        ))
        // Remembers size and position between uses.
        if !window.setFrameUsingName("PixSEOEditor") { window.center() }
        window.setFrameAutosaveName("PixSEOEditor")
    }

    func show() {
        ActivationPolicyManager.shared.opened(window)
        window.makeKeyAndOrderFront(nil)
        model.start()
    }

    /// Closes without asking (after saving).
    func close() {
        model.markSaved()
        window.close()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard model.hasChanges else { return true }
        let alert = NSAlert()
        alert.messageText = "Đóng mà không lưu?"
        alert.informativeText = "Các chỉnh sửa crop và watermark trong cửa sổ này sẽ mất."
        alert.addButton(withTitle: "Đóng")
        alert.addButton(withTitle: "Hủy")
        return alert.runModal() == .alertFirstButtonReturn
    }

    func windowWillClose(_ notification: Notification) {
        model.suggestions.cancel()
        model.estimator.cancel()
        ActivationPolicyManager.shared.closed(window)
        onClosed(self)
    }
}
