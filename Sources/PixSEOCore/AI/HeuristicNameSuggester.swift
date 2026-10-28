import Foundation

/// Fast, always-available suggestions: the most prominent text in the picture (a banner's
/// title), or failing that its scene labels in Vietnamese.
public enum HeuristicNameSuggester {
    public static func suggest(analysis: ContentAnalysis) -> NameSuggestion? {
        fromText(analysis.lines) ?? fromLabels(analysis.labels)
    }

    /// Biggest line first; a short title borrows the next line of similar size ("KHAI GIẢNG" +
    /// "K15"). Lines without at least 3 letters (dates, prices) are skipped.
    static func fromText(_ lines: [ContentAnalysis.TextLine]) -> NameSuggestion? {
        let usable = lines.filter { $0.text.filter(\.isLetter).count >= 3 }.sorted { $0.height > $1.height }
        guard let top = usable.first else { return nil }
        var words = top.text.split(separator: " ").map(String.init)
        if words.count < 3, let next = usable.dropFirst().first, next.height >= top.height * 0.6 {
            words += next.text.split(separator: " ").map(String.init)
        }
        let title = sentenceCase(words.prefix(7).joined(separator: " "))
        let alt = usable.prefix(2).map { sentenceCase($0.text) }.joined(separator: ": ")
        return NameSuggestion.validated(title: title, altText: alt, source: .text)
    }

    static func fromLabels(_ labels: [String]) -> NameSuggestion? {
        let words = labels.compactMap(VietnameseLabelDictionary.word(for:))
        var unique: [String] = []
        for word in words where !unique.contains(word) { unique.append(word) }
        guard !unique.isEmpty else { return nil }
        return NameSuggestion.validated(title: unique.prefix(3).joined(separator: " "), altText: nil, source: .labels)
    }

    /// "KHAI GIẢNG K15" → "Khai giảng K15": all-caps words lowered unless they look like codes
    /// (contain a digit or are ≤ 3 letters, like AI, SEO, K15).
    static func sentenceCase(_ text: String) -> String {
        let isShouting = text == text.uppercased() && text.contains(where: \.isLetter)
        guard isShouting else { return text }
        let words = text.split(separator: " ").enumerated().map { index, word -> String in
            let keep = word.contains(where: \.isNumber) || (word.count <= 3 && index > 0)
            let lower = keep ? String(word) : word.lowercased()
            return index == 0 ? lower.prefix(1).uppercased() + lower.dropFirst() : lower
        }
        return words.joined(separator: " ")
    }
}
