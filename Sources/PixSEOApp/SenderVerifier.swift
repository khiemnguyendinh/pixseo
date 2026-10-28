import AppKit
import Darwin

/// Decides whether a `pixseo://` URL event was sent by PixSEO's own Finder extension.
///
/// Any app or web page can open a `pixseo://` URL, so only requests whose sender process lives
/// inside this app's `Contents/PlugIns` folder are trusted to export without a confirmation panel.
enum SenderVerifier {
    static func isOwnFinderExtension(_ event: NSAppleEventDescriptor) -> Bool {
        guard let pid = event.attributeDescriptor(forKeyword: AEKeyword(keySenderPIDAttr))?.int32Value,
              pid > 0,
              let senderPath = executablePath(of: pid)
        else { return false }

        let plugIns = Bundle.main.bundleURL
            .appendingPathComponent("Contents/PlugIns", isDirectory: true)
            .resolvingSymlinksInPath().path + "/"
        return senderPath.hasPrefix(plugIns)
    }

    private static func executablePath(of pid: pid_t) -> String? {
        // PROC_PIDPATHINFO_MAXSIZE is 4 * MAXPATHLEN.
        var buffer = [CChar](repeating: 0, count: 4 * Int(MAXPATHLEN))
        guard proc_pidpath(pid, &buffer, UInt32(buffer.count)) > 0 else { return nil }
        return buffer.withUnsafeBufferPointer { String(cString: $0.baseAddress!) }
    }
}
