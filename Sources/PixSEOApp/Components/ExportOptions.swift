import Foundation
import Observation
import PixSEOCore
import PixSEOShared

/// Size, format, quality, byte limit and PPI the user picked. Shared by the Quick Save panel
/// and the editor so both behave the same and remember the same choices.
@MainActor
@Observable
final class ExportOptions {
    /// Picker tag for "type a width".
    static let customWidthTag = 0

    var widthChoice: Int
    var customWidthText: String
    var resizeMode: ResizeMode
    var format: OutputFormat
    var quality: Double
    var targetKB: Int?
    var ppi: Int
    var sharpen: Bool

    init(preferences: ExportPreferences, width: Int? = nil) {
        let width = width ?? preferences.width
        widthChoice = SizePresets.widths.contains(width) ? width : Self.customWidthTag
        customWidthText = SizePresets.widths.contains(width) ? "" : String(width)
        resizeMode = preferences.resizeMode
        format = preferences.format
        quality = preferences.quality
        targetKB = preferences.targetKB
        ppi = preferences.ppi
        sharpen = preferences.sharpen
    }

    /// Copies another model's choices (Quick Save → Editor keeps what the user already set).
    convenience init(copying other: ExportOptions) {
        self.init(preferences: ExportPreferences())
        widthChoice = other.widthChoice
        customWidthText = other.customWidthText
        resizeMode = other.resizeMode
        format = other.format
        quality = other.quality
        targetKB = other.targetKB
        ppi = other.ppi
        sharpen = other.sharpen
    }

    /// `nil` keeps the size.
    var width: Int? {
        guard widthChoice == Self.customWidthTag else { return widthChoice }
        return Int(customWidthText.trimmingCharacters(in: .whitespaces)).flatMap { $0 > 0 ? $0 : nil }
    }

    func resize(fixedSize: PixelSize? = nil) -> ResizeSpec {
        ResizeSpec(mode: fixedSize == nil ? resizeMode : .width, value: fixedSize?.width ?? width, fixedSize: fixedSize)
    }

    var settings: ExportSettings {
        ExportSettings(format: format, quality: quality, targetBytes: targetKB.map { $0 * 1024 }, ppi: ppi)
    }

    /// Changes whenever anything that affects the output changes; views re-estimate on it.
    var fingerprint: [AnyHashable] { [widthChoice, customWidthText, resizeMode, format, quality, targetKB, ppi, sharpen] }

    func store(into preferences: inout ExportPreferences) {
        preferences.format = format
        preferences.quality = quality
        preferences.targetKB = targetKB
        preferences.ppi = ppi
        preferences.resizeMode = resizeMode
        preferences.sharpen = sharpen
        if let width { preferences.width = width }
    }
}
