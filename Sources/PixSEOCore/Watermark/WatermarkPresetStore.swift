import Foundation

/// A named watermark the user saved for reuse.
public struct WatermarkPreset: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var name: String
    public var spec: WatermarkSpec

    public init(id: UUID = UUID(), name: String, spec: WatermarkSpec) {
        self.id = id
        self.name = name
        self.spec = spec
    }
}

/// Saved watermark presets plus their logo files, in `<directory>/watermark-presets.json` and
/// `<directory>/Logos/`. Logos are copies, so the user may delete or move the original.
public final class WatermarkPresetStore {
    private struct Contents: Codable {
        var presets: [WatermarkPreset] = []
        var defaultID: UUID?
    }

    public let directory: URL
    private var contents: Contents

    public var presets: [WatermarkPreset] { contents.presets }
    public var defaultID: UUID? { contents.defaultID }
    public var defaultPreset: WatermarkPreset? { presets.first { $0.id == defaultID } }
    private var fileURL: URL { directory.appendingPathComponent("watermark-presets.json") }
    private var logosURL: URL { directory.appendingPathComponent("Logos") }

    public init(directory: URL) {
        self.directory = directory
        let url = directory.appendingPathComponent("watermark-presets.json")
        contents = (try? Data(contentsOf: url)).flatMap { try? JSONDecoder().decode(Contents.self, from: $0) } ?? Contents()
    }

    /// Adds the preset, or replaces the one with the same id.
    public func save(_ preset: WatermarkPreset) throws {
        let old = contents.presets.first { $0.id == preset.id }
        if let index = contents.presets.firstIndex(where: { $0.id == preset.id }) {
            contents.presets[index] = preset
        } else {
            contents.presets.append(preset)
        }
        if contents.defaultID == nil { contents.defaultID = preset.id }
        try persist()
        if let old { removeUnusedLogo(of: old.spec) }
    }

    public func rename(_ id: UUID, to name: String) throws {
        guard let index = contents.presets.firstIndex(where: { $0.id == id }) else { return }
        contents.presets[index].name = name
        try persist()
    }

    /// Deletes the preset, and its logo file when no other preset uses it.
    public func delete(_ id: UUID) throws {
        guard let removed = contents.presets.first(where: { $0.id == id }) else { return }
        contents.presets.removeAll { $0.id == id }
        if contents.defaultID == id { contents.defaultID = contents.presets.first?.id }
        try persist()
        removeUnusedLogo(of: removed.spec)
    }

    public func setDefault(_ id: UUID?) throws {
        contents.defaultID = id
        try persist()
    }

    /// Copies a logo into the store and returns the copy's path for `WatermarkSpec.Kind.logo`.
    public func importLogo(from source: URL) throws -> String {
        try FileManager.default.createDirectory(at: logosURL, withIntermediateDirectories: true)
        let ext = source.pathExtension.isEmpty ? "png" : source.pathExtension.lowercased()
        let destination = logosURL.appendingPathComponent("\(UUID().uuidString).\(ext)")
        try FileManager.default.copyItem(at: source, to: destination)
        return destination.path
    }

    private func persist() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(contents).write(to: fileURL, options: .atomic)
    }

    /// Only files inside our Logos folder are ever deleted.
    private func removeUnusedLogo(of spec: WatermarkSpec) {
        guard case .logo(let path) = spec.kind,
              URL(fileURLWithPath: path).deletingLastPathComponent().standardizedFileURL == logosURL.standardizedFileURL,
              !presets.contains(where: { $0.spec.kind == spec.kind })
        else { return }
        try? FileManager.default.removeItem(atPath: path)
    }
}
