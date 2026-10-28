import Foundation
import Observation
import PixSEOCore

/// The name field(s): one name for a single image, or for a batch either a shared name with
/// numbers or each file's own name.
@MainActor
@Observable
final class FileNaming {
    let files: [URL]
    /// Never changed by code after init, so Vietnamese input methods (which keep uncommitted
    /// marked text in the field) are never disturbed. Suggestions are applied by the user.
    var nameInput: String
    let namePlaceholder: String
    var usesSharedName: Bool
    var sharedName: String
    /// True when the source name means nothing (IMG_4521, Zalo exports…).
    let sourceIsMeaningless: Bool

    init(files: [URL], typedName: String? = nil) {
        self.files = files
        // A meaningful name is pre-filled for editing; a camera/Zalo name is only shown as a
        // placeholder so typing replaces it without having to delete it first.
        let first = files.first?.deletingPathExtension().lastPathComponent ?? ""
        let slug = SEOSlugger.slugify(first)
        sourceIsMeaningless = MeaninglessNameDetector.isMeaningless(first)
        nameInput = typedName ?? (sourceIsMeaningless ? "" : slug)
        namePlaceholder = sourceIsMeaningless ? "Mô tả ảnh, vd: khai giảng k15" : slug

        switch ExportAdvisor.defaultBatchMode(for: files.map(\.lastPathComponent)) {
        case .individual:
            usesSharedName = false
            sharedName = ""
        case .shared(let base):
            usesSharedName = true
            sharedName = base
        }
    }

    var isBatch: Bool { files.count > 1 }

    var mode: BatchNameMode { usesSharedName && isBatch ? .shared(sharedName) : .individual }

    /// A shared name must be typed before saving a batch under it.
    var isComplete: Bool {
        !files.isEmpty && !(isBatch && usesSharedName && sharedName.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    /// Text typed into whichever field is active.
    var currentText: String { isBatch ? sharedName : nameInput }

    /// Name for a single image: what the user typed, else a suggestion (applied without
    /// touching the text field), else the source file name (`nil`).
    func singleName(suggested: String?) -> String? {
        let typed = nameInput.trimmingCharacters(in: .whitespaces)
        return typed.isEmpty ? suggested : typed
    }

    /// Final name of the first file, shown under the name field. Uses the first image's size
    /// for every item so it never touches the other files while the user types.
    func preview(outputSize: PixelSize?, format: OutputFormat, namer: OutputFileNamer, suggested: String? = nil) -> String {
        guard let first = files.first, let size = outputSize else { return "" }
        let input = isBatch ? first.lastPathComponent : singleName(suggested: suggested) ?? first.lastPathComponent
        let item = OutputFileNamer.Item(input: input, outputSize: size, directory: first.deletingLastPathComponent())
        let items = Array(repeating: item, count: mode == .individual ? 1 : files.count)
        let name = namer.plan(items, mode: mode, fileExtension: format.fileExtension).first?.lastPathComponent ?? ""
        return isBatch ? "\(name) … (\(files.count) ảnh)" : name
    }
}
