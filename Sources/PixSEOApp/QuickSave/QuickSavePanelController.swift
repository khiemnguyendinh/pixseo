import AppKit
import SwiftUI

/// Floating panel that hosts `QuickSaveView`, centered on the screen under the pointer.
@MainActor
final class QuickSavePanelController: NSObject, NSWindowDelegate {
    private let panel: NSPanel
    private let onClose: (QuickSavePanelController) -> Void

    init(model: QuickSaveViewModel, onSave: @escaping (QuickSavePanelController) -> Void,
         onOpenEditor: @escaping (QuickSavePanelController) -> Void,
         onClose: @escaping (QuickSavePanelController) -> Void) {
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 600, height: 380),
                        styleMask: [.titled, .closable], backing: .buffered, defer: false)
        self.onClose = onClose
        super.init()

        panel.title = "Quick Resize"
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.delegate = self
        // A plain hosting view sizes the window through Auto Layout as the content grows (advice
        // lines appear). A full-size content view plus a sizing hosting controller made AppKit and
        // SwiftUI resize each other in a loop and crash on open.
        panel.contentView = NSHostingView(rootView: QuickSaveView(
            model: model,
            onCancel: { [weak self] in self?.close() },
            onSave: { [weak self] in if let self { onSave(self) } },
            onOpenEditor: { [weak self] in if let self { onOpenEditor(self) } }
        ))
    }

    /// `offset` staggers panels when several requests arrive at once.
    func show(offset: Int) {
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main
        if let area = screen?.visibleFrame {
            let size = panel.frame.size
            let shift = CGFloat(offset) * 24
            panel.setFrameOrigin(NSPoint(x: area.midX - size.width / 2 + shift,
                                         y: area.midY - size.height / 2 + area.height / 10 - shift))
        }
        // An accessory app must activate itself for the name field to receive typing.
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
    }

    func close() {
        panel.close()
    }

    func windowWillClose(_ notification: Notification) {
        onClose(self)
    }
}
