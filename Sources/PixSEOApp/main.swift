import AppKit

// AppKit lifecycle: PixSEO is an accessory app (LSUIElement) that shows panels on demand,
// so it doesn't use SwiftUI's App/WindowGroup scenes.
let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.run()
