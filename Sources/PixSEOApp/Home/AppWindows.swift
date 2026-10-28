import AppKit
import SwiftUI

/// A single reusable window (Home, Settings) hosting a SwiftUI view. While visible, PixSEO shows
/// in the Dock and ⌘Tab.
@MainActor
final class SingleWindowController<Content: View>: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private let title: String
    private let content: () -> Content

    init(title: String, content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    func show() {
        if window == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 300),
                                  styleMask: [.titled, .closable], backing: .buffered, defer: false)
            window.title = title
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.contentView = NSHostingView(rootView: content())
            window.center()
            self.window = window
        }
        guard let window else { return }
        ActivationPolicyManager.shared.opened(window)
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        if let window { ActivationPolicyManager.shared.closed(window) }
    }
}

/// App, Edit and Window menus. Even without a visible menu bar, these key equivalents make
/// ⌘C/⌘V/⌘A/⌘Z work in text fields and ⌘, open Settings.
enum MainMenu {
    @MainActor
    static func install(settings: Selector, target: AnyObject) {
        let main = NSMenu()

        let app = NSMenu()
        app.addItem(withTitle: "Giới thiệu PixSEO", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        app.addItem(.separator())
        let settingsItem = app.addItem(withTitle: "Cài đặt…", action: settings, keyEquivalent: ",")
        settingsItem.target = target
        app.addItem(.separator())
        app.addItem(withTitle: "Ẩn PixSEO", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        app.addItem(withTitle: "Thoát PixSEO", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        main.addItem(submenu(app, title: "PixSEO"))

        let edit = NSMenu(title: "Sửa")
        edit.addItem(withTitle: "Hoàn tác", action: Selector(("undo:")), keyEquivalent: "z")
        edit.addItem(withTitle: "Làm lại", action: Selector(("redo:")), keyEquivalent: "Z")
        edit.addItem(.separator())
        edit.addItem(withTitle: "Cắt", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Sao chép", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Dán", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Chọn tất cả", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        main.addItem(submenu(edit, title: "Sửa"))

        let window = NSMenu(title: "Cửa sổ")
        window.addItem(withTitle: "Đóng", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        window.addItem(withTitle: "Thu nhỏ", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        main.addItem(submenu(window, title: "Cửa sổ"))
        NSApp.windowsMenu = window

        NSApp.mainMenu = main
    }

    private static func submenu(_ menu: NSMenu, title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = menu
        return item
    }
}
