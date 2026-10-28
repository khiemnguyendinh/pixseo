import Foundation
import PixSEOShared

/// Turns any text into an SEO file-name slug: lowercase ASCII, Vietnamese diacritics removed,
/// words joined by hyphens. "Khai Giảng K15" → "khai-giang-k15".
public enum SEOSlugger {
    public static let defaultMaxLength = 60
    /// Used when nothing usable is left, e.g. a name made only of emoji.
    public static let fallback = "anh"

    /// ICU handles both precomposed (NFC) and decomposed (NFD) input; "đ" has no decomposition,
    /// so it is mapped explicitly before the transform.
    private static let toASCII = StringTransform("Any-Latin; Latin-ASCII; Any-Lower")

    public static func slugify(_ text: String, maxLength: Int = defaultMaxLength) -> String {
        let latin = text
            .replacingOccurrences(of: "đ", with: "d")
            .replacingOccurrences(of: "Đ", with: "D")
        let ascii = latin.applyingTransform(toASCII, reverse: false) ?? latin.lowercased()

        var slug = ""
        var pendingHyphen = false
        for scalar in ascii.unicodeScalars {
            if ("a"..."z").contains(scalar) || ("0"..."9").contains(scalar) {
                if pendingHyphen, !slug.isEmpty { slug.append("-") }
                slug.unicodeScalars.append(scalar)
                pendingHyphen = false
            } else {
                pendingHyphen = true
            }
        }

        let cut = truncate(slug, to: maxLength)
        return cut.isEmpty ? fallback : cut
    }

    /// Removes an image extension the user typed together with the name ("banner.webp").
    public static func stripImageExtension(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let ext = (trimmed as NSString).pathExtension.lowercased()
        guard SupportedImageTypes.fileExtensions.contains(ext) else { return trimmed }
        return (trimmed as NSString).deletingPathExtension
    }

    /// Cuts at the last hyphen that fits, so words are never split.
    static func truncate(_ slug: String, to maxLength: Int) -> String {
        guard slug.count > maxLength else { return slug }
        let prefix = slug.prefix(maxLength)
        if slug[prefix.endIndex] == "-" { return String(prefix) }
        guard let lastHyphen = prefix.lastIndex(of: "-") else { return String(prefix) }
        return String(prefix[..<lastHyphen])
    }
}
