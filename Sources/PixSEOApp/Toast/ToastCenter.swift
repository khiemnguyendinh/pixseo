import AppKit
import Observation
import SwiftUI

/// A button on a toast.
struct ToastAction: Identifiable {
    let id = UUID()
    let title: String
    let perform: @MainActor () -> Void
}

/// Content of one toast; updating it (e.g. progress → result) updates the panel in place.
@MainActor
@Observable
final class ToastModel {
    enum Style { case progress, success, warning, failure }

    var style: Style
    var title: String
    var detail: String?
    var actions: [ToastAction]
    var isHovered = false

    init(style: Style, title: String, detail: String? = nil, actions: [ToastAction] = []) {
        self.style = style
        self.title = title
        self.detail = detail
        self.actions = actions
    }
}

/// Small notices in the top-right corner that never take focus from the app the user is in.
/// Result toasts hide after 6 s (longer while the pointer is over them); progress toasts stay
/// until updated.
@MainActor
final class ToastCenter {
    static let shared = ToastCenter()
    private static let size = NSSize(width: 420, height: 92)
    private var panels: [(model: ToastModel, panel: NSPanel)] = []

    @discardableResult
    func show(_ model: ToastModel) -> ToastModel {
        let panel = NSPanel(contentRect: NSRect(origin: .zero, size: Self.size),
                            styleMask: [.nonactivatingPanel, .borderless], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.contentView = NSHostingView(rootView: ToastView(model: model) { [weak self, weak model] in
            if let model { self?.dismiss(model) }
        })
        panels.append((model, panel))
        layout()
        panel.orderFrontRegardless()
        if model.style != .progress { scheduleDismiss(model) }
        return model
    }

    /// Turns a progress toast into its final state and starts its dismiss timer.
    func finish(_ model: ToastModel) {
        scheduleDismiss(model)
    }

    func isShowing(_ model: ToastModel) -> Bool {
        panels.contains { $0.model === model }
    }

    func dismiss(_ model: ToastModel) {
        guard let index = panels.firstIndex(where: { $0.model === model }) else { return }
        panels.remove(at: index).panel.orderOut(nil)
        layout()
    }

    private func scheduleDismiss(_ model: ToastModel) {
        Task { [weak self, weak model] in
            try? await Task.sleep(for: .seconds(6))
            while model?.isHovered == true { try? await Task.sleep(for: .seconds(1)) }
            if let model { self?.dismiss(model) }
        }
    }

    /// Stacks toasts downward from the top-right of the screen under the pointer.
    private func layout() {
        let screen = NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) } ?? NSScreen.main
        guard let area = screen?.visibleFrame else { return }
        for (index, entry) in panels.enumerated() {
            let origin = NSPoint(x: area.maxX - Self.size.width - 16,
                                 y: area.maxY - 16 - CGFloat(index + 1) * (Self.size.height + 8))
            entry.panel.setFrame(NSRect(origin: origin, size: Self.size), display: true)
        }
    }
}
