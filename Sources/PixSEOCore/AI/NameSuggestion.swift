import Foundation

/// A suggested file name (and alt text) with where it came from.
public struct NameSuggestion: Sendable, Equatable {
    public enum Source: Sendable, Equatable {
        /// Text read from the picture (banner titles).
        case text
        /// Scene labels translated to Vietnamese.
        case labels
        /// Apple's on-device language model.
        case onDevice
    }

    /// Vietnamese with diacritics, e.g. "Khai giảng K15 khóa AI marketing".
    public let title: String
    /// Built by `SEOSlugger` from `title`; the model is never trusted to strip diacritics.
    public let slug: String
    public let altText: String?
    public let source: Source

    public static let maxWords = 8
    public static let maxAltLength = 125

    /// Checks a raw suggestion: empty, longer than 8 words or still meaningless titles are
    /// rejected; alt text is cut to 125 characters at a word boundary.
    public static func validated(title: String, altText: String?, source: Source) -> NameSuggestion? {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        let slug = SEOSlugger.slugify(cleanTitle)
        let words = slug.split(separator: "-")
        guard !cleanTitle.isEmpty, slug != SEOSlugger.fallback, words.count <= maxWords,
              !MeaninglessNameDetector.isMeaningless(slug)
        else { return nil }
        let alt = altText.map(trimAlt).flatMap { $0.isEmpty ? nil : $0 }
        return NameSuggestion(title: cleanTitle, slug: slug, altText: alt, source: source)
    }

    /// One line, ≤ 125 characters, cut at a word boundary; drops a "Hình ảnh của" opener.
    public static func trimAlt(_ text: String) -> String {
        var alt = text.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces)
        for opener in ["Hình ảnh của ", "Ảnh của ", "Hình ảnh "] where alt.hasPrefix(opener) {
            alt.removeFirst(opener.count)
            alt = alt.prefix(1).uppercased() + alt.dropFirst()
            break
        }
        guard alt.count > maxAltLength else { return alt }
        let cut = alt.prefix(maxAltLength)
        let trimmed = cut.lastIndex(of: " ").map { cut[..<$0] } ?? cut
        return trimmed.trimmingCharacters(in: .punctuationCharacters.union(.whitespaces))
    }
}
