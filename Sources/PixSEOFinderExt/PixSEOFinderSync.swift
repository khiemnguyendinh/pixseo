import Cocoa
import FinderSync

/// Finder context menu for images: Quick Resize ▸ widths, Quick Crop…, Quick Watermark….
///
/// The extension is sandboxed and cannot read files, so it filters the selection by file
/// extension and hands everything else to the app through a `pixseo://run` URL.
/// The menu is static on purpose: without an App Group the extension can't read the app's
/// settings, so all state (format, quality, name) lives in the app.
/// Built by scripts/build-app.sh together with Sources/PixSEOShared.
@objc(PixSEOFinderSync)
final class PixSEOFinderSync: FIFinderSync {
    override init() {
        super.init()
        // Watching "/" makes the menu available everywhere, including other volumes.
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForItems, !selectedImages().isEmpty else { return nil }

        // Finder copies menu items and drops `representedObject`, so the width travels in `tag`;
        // tag 0 means "let me type a width".
        let widths = NSMenu(title: "Quick Resize")
        for width in SizePresets.widths {
            let title = width == 3840 ? "4K · 3840 px" : "\(width) px"
            widths.addItem(withTitle: title, action: #selector(quickResize(_:)), keyEquivalent: "").tag = width
        }
        widths.addItem(.separator())
        widths.addItem(withTitle: "Tùy chỉnh…", action: #selector(quickResize(_:)), keyEquivalent: "").tag = 0

        let menu = NSMenu(title: "")
        menu.addItem(withTitle: "Quick Resize", action: nil, keyEquivalent: "").submenu = widths
        menu.addItem(withTitle: "Quick Crop…", action: #selector(quickCrop(_:)), keyEquivalent: "")
        menu.addItem(withTitle: "Quick Watermark…", action: #selector(quickWatermark(_:)), keyEquivalent: "")
        return menu
    }

    @objc func quickResize(_ sender: NSMenuItem) {
        send(.resize, width: sender.tag > 0 ? sender.tag : nil)
    }

    @objc func quickCrop(_ sender: NSMenuItem) {
        send(.crop, width: nil)
    }

    @objc func quickWatermark(_ sender: NSMenuItem) {
        send(.watermark, width: nil)
    }

    private func selectedImages() -> [URL] {
        (FIFinderSyncController.default().selectedItemURLs() ?? []).filter(SupportedImageTypes.isImage)
    }

    private func send(_ action: IntakeAction, width: Int?) {
        let files = selectedImages()
        guard !files.isEmpty else { return }
        for url in IntakeRequest(action: action, width: width, files: files).makeURLs() {
            NSWorkspace.shared.open(url)
        }
    }
}
