import Foundation
import Observation
import PixSEOCore

/// User choices that persist between uses. Panels open with whatever was used last.
struct ExportPreferences: Codable, Equatable {
    var format: OutputFormat = .webp
    var quality: Double = 0.80
    /// Byte limit in KB; `nil` = no limit.
    var targetKB: Int?
    var ppi: Int = 72
    var width: Int = 1920
    var resizeMode: ResizeMode = .width
    var sizeSuffix: SizeSuffix = .width
    /// Light sharpening after a strong downscale.
    var sharpen = true
    /// Show the Quick Save panel (with the name field) even when the width was picked in the menu.
    var askNameBeforeSave = true
    var idleQuitMinutes = 15
    /// Watermark preset applied by the Quick Resize panel; `nil` = none.
    var quickSaveWatermarkID: UUID?
    /// Last watermark used in the editor, offered again when there is no preset.
    var lastWatermark: WatermarkSpec?
    var aiEnabled = true
    /// e.g. "Kstudy Academy, đào tạo AI và marketing"; given to the name suggester.
    var brandContext = ""
    var autoCopyAlt = true
    var onboardingDone = false

    init() {}

    /// Missing keys (settings saved by an older version) keep their defaults instead of
    /// discarding everything the user chose.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = ExportPreferences()
        format = try c.decodeIfPresent(OutputFormat.self, forKey: .format) ?? d.format
        quality = try c.decodeIfPresent(Double.self, forKey: .quality) ?? d.quality
        targetKB = try c.decodeIfPresent(Int.self, forKey: .targetKB)
        ppi = try c.decodeIfPresent(Int.self, forKey: .ppi) ?? d.ppi
        width = try c.decodeIfPresent(Int.self, forKey: .width) ?? d.width
        resizeMode = try c.decodeIfPresent(ResizeMode.self, forKey: .resizeMode) ?? d.resizeMode
        sizeSuffix = try c.decodeIfPresent(SizeSuffix.self, forKey: .sizeSuffix) ?? d.sizeSuffix
        sharpen = try c.decodeIfPresent(Bool.self, forKey: .sharpen) ?? d.sharpen
        askNameBeforeSave = try c.decodeIfPresent(Bool.self, forKey: .askNameBeforeSave) ?? d.askNameBeforeSave
        idleQuitMinutes = try c.decodeIfPresent(Int.self, forKey: .idleQuitMinutes) ?? d.idleQuitMinutes
        quickSaveWatermarkID = try c.decodeIfPresent(UUID.self, forKey: .quickSaveWatermarkID)
        lastWatermark = try c.decodeIfPresent(WatermarkSpec.self, forKey: .lastWatermark)
        aiEnabled = try c.decodeIfPresent(Bool.self, forKey: .aiEnabled) ?? d.aiEnabled
        brandContext = try c.decodeIfPresent(String.self, forKey: .brandContext) ?? d.brandContext
        autoCopyAlt = try c.decodeIfPresent(Bool.self, forKey: .autoCopyAlt) ?? d.autoCopyAlt
        onboardingDone = try c.decodeIfPresent(Bool.self, forKey: .onboardingDone) ?? d.onboardingDone
    }
}

@MainActor
@Observable
final class SettingsStore {
    static let shared = SettingsStore()
    private static let key = "exportPreferences"

    var preferences: ExportPreferences {
        didSet {
            guard preferences != oldValue, let data = try? JSONEncoder().encode(preferences) else { return }
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }

    /// Saved watermark presets, in ~/Library/Application Support/PixSEO.
    let watermarkPresets: WatermarkPresetStore

    private init() {
        // Corrupt data falls back to defaults instead of failing.
        preferences = UserDefaults.standard.data(forKey: Self.key)
            .flatMap { try? JSONDecoder().decode(ExportPreferences.self, from: $0) } ?? ExportPreferences()
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        watermarkPresets = WatermarkPresetStore(directory: support.appendingPathComponent("PixSEO"))
    }
}
