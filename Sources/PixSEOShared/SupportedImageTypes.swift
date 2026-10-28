import Foundation

/// Image file types PixSEO accepts.
///
/// The Finder extension is sandboxed and cannot read files or their metadata, so the check is
/// done on the file extension only. The app re-validates every file with ImageIO later.
/// SVG and PDF are left out on purpose: they are vector formats and already small on the web.
public enum SupportedImageTypes {
    public static let fileExtensions: Set<String> = [
        "jpg", "jpeg", "png", "gif", "webp", "heic", "heif", "avif", "tif", "tiff", "bmp", "psd",
    ]

    public static func isImage(_ url: URL) -> Bool {
        url.isFileURL && fileExtensions.contains(url.pathExtension.lowercased())
    }
}
