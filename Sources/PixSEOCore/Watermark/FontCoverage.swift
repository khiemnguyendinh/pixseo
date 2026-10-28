import CoreText
import Foundation

/// Checks whether a font can write Vietnamese, so fonts missing diacritics can be flagged.
public enum FontCoverage {
    /// Every precomposed Vietnamese letter with a diacritic, lower and upper case.
    public static let vietnameseLetters: String = {
        let lower = "ăâđêôơưàảãáạằẳẵắặầẩẫấậèẻẽéẹềểễếệìỉĩíịòỏõóọồổỗốộờởỡớợùủũúụừửữứựỳỷỹýỵ"
        return lower + lower.uppercased()
    }()

    public static func supportsVietnamese(family: String) -> Bool {
        let descriptor = CTFontDescriptorCreateWithAttributes([kCTFontFamilyNameAttribute: family] as CFDictionary)
        let font = CTFontCreateWithFontDescriptor(descriptor, 12, nil)
        // An unknown family falls back to another font; don't vouch for it.
        guard (CTFontCopyFamilyName(font) as String) == family else { return false }
        return covers(CTFontCopyCharacterSet(font))
    }

    public static func covers(_ set: CFCharacterSet) -> Bool {
        vietnameseLetters.unicodeScalars.allSatisfy { CFCharacterSetIsLongCharacterMember(set, $0.value) }
    }
}
