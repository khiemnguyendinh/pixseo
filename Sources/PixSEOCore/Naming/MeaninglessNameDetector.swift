import Foundation

/// Spots file names that carry no SEO value: camera and phone defaults, screenshots,
/// Zalo/Messenger/Facebook downloads, hashes, and AI-tool exports.
///
/// Matching runs on the slug, so accents, case, spaces and underscores don't matter
/// ("Ảnh màn hình 2026…" and "anh_man_hinh" both become "anh-man-hinh…").
public enum MeaninglessNameDetector {
    // NSRegularExpression is immutable and thread-safe, unlike Swift's non-Sendable Regex.
    private static let patterns: [NSRegularExpression] = [
        #"^(img|dsc|dscn|dscf|dji|gopr|pxl|mvimg|photo|image|pic|anh|hinh)(-?\d+|$)"#,
        #"^(screen-?shot|anh-man-hinh|chup-man-hinh|cleanshot|capture)"#,
        #"^z\d{6,}-[0-9a-f]{16,}"#,                     // Zalo
        #"^received-\d+"#,                              // Messenger
        #"^fb-img-\d+"#,                                // Facebook
        #"^\d{8,}(-\d+)*$"#,                            // long numeric ids and timestamps
        #"^[0-9a-f]{8}-[0-9a-f]{4}-"#,                  // UUID
        #"^[0-9a-f]{24,}$"#,                            // hash
        #"^(chatgpt-image|gemini-generated-image|dall-?e|midjourney|firefly)"#,
        #"^(download|tai-xuong|unnamed|untitled)(-\d+)?$"#,
    ].map { try! NSRegularExpression(pattern: $0) }

    /// `name` may include an extension; it is ignored.
    public static func isMeaningless(_ name: String) -> Bool {
        let slug = SEOSlugger.slugify(SEOSlugger.stripImageExtension(name), maxLength: .max)
        if slug.filter(\.isLetter).count < 3 { return true }
        let range = NSRange(slug.startIndex..., in: slug)
        return patterns.contains { $0.firstMatch(in: slug, range: range) != nil }
    }
}
