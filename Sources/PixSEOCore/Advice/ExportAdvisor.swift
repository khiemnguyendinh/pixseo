import Foundation

/// Decisions the export UI shows to the user, kept out of the views so they can be tested.
public enum ExportAdvisor {
    /// One-line advice about the current choice. The app turns each case into Vietnamese text.
    public enum Advice: Hashable, Sendable {
        case pngForPhoto
        case gifForStill
        case transparencyWillBeWhite
        case notUpscaled(original: PixelSize)
        case fourKForWeb
        case largerThanSource(percent: Int)
        case targetNotMet(suggestedWidth: Int?)
        case animationDropped
        case dimensionTooLarge(max: Int)
    }

    /// Color of the estimated-size badge: green ≤ 200 KB, amber ≤ 500 KB, red above.
    public enum SizeBadge: Sendable { case good, fair, heavy }

    public static func sizeBadge(bytes: Int) -> SizeBadge {
        bytes <= 200 * 1024 ? .good : bytes <= 500 * 1024 ? .fair : .heavy
    }

    /// Advice for a source and settings, plus whatever the last estimate reported.
    public static func advice(info: SourceImageInfo?, format: OutputFormat, width: Int?, estimateWarnings: [ExportWarning]) -> [Advice] {
        var advice: [Advice] = []
        if let info {
            if format == .png, info.contentKind == .photo { advice.append(.pngForPhoto) }
            if format == .gif, info.frameCount == 1 { advice.append(.gifForStill) }
            if format == .jpeg, info.hasTransparency { advice.append(.transparencyWillBeWhite) }
        }
        if let width, width >= 3840 { advice.append(.fourKForWeb) }
        for warning in estimateWarnings {
            switch warning {
            case .notUpscaled(let original): advice.append(.notUpscaled(original: original))
            case .largerThanSource(let percent): advice.append(.largerThanSource(percent: percent))
            case .targetNotMet(let suggested): advice.append(.targetNotMet(suggestedWidth: suggested))
            case .animationDropped: advice.append(.animationDropped)
            case .alphaFlattened, .ppiIgnored: break   // covered above / shown as a disabled control
            }
        }
        return advice
    }

    /// How a batch should be named by default. One image, or names that already mean something,
    /// keep their own names; otherwise one shared base, pre-filled with the meaningful part the
    /// names have in common ("" when there is none, so the user types one).
    public static func defaultBatchMode(for fileNames: [String]) -> BatchNameMode {
        guard fileNames.count > 1 else { return .individual }
        if fileNames.allSatisfy({ !MeaninglessNameDetector.isMeaningless($0) }) { return .individual }
        return .shared(commonMeaningfulPrefix(fileNames))
    }

    /// Longest run of whole slug words shared by every name, if it is meaningful on its own.
    /// ["Lễ khai giảng 1.jpg", "le-khai-giang-2.jpg"] → "le-khai-giang".
    public static func commonMeaningfulPrefix(_ fileNames: [String]) -> String {
        let words = fileNames.map {
            SEOSlugger.slugify(SEOSlugger.stripImageExtension($0), maxLength: .max).split(separator: "-")
        }
        guard var prefix = words.first else { return "" }
        for other in words.dropFirst() {
            prefix = Array(zip(prefix, other).prefix { $0 == $1 }.map(\.0))
        }
        let joined = prefix.joined(separator: "-")
        return joined.isEmpty || MeaninglessNameDetector.isMeaningless(joined) ? "" : joined
    }
}
