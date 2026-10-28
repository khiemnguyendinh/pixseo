import Foundation
import PixSEOCore

/// Vietnamese wording for advice, errors and sizes, in one place so the UI stays consistent.
enum UserFacingText {
    static func bytes(_ count: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(count), countStyle: .file)
    }

    /// "−96%", or "+12%" when the file grew.
    static func savings(from source: Int, to output: Int) -> String {
        guard source > 0 else { return "" }
        var percent = Int((Double(output - source) / Double(source) * 100).rounded())
        // A file still exists, so never claim −100%.
        if output > 0 { percent = max(percent, -99) }
        return percent <= 0 ? "−\(-percent)%" : "+\(percent)%"
    }

    static func advice(_ advice: ExportAdvisor.Advice) -> String {
        switch advice {
        case .pngForPhoto: "PNG cho ảnh chụp thường nặng gấp 5–10 lần WebP."
        case .gifForStill: "GIF chỉ có 256 màu nên ảnh kém đẹp. Nên dùng WebP."
        case .transparencyWillBeWhite: "JPEG không có nền trong suốt: phần trong suốt sẽ thành nền trắng."
        case .notUpscaled(let original): "Ảnh gốc nhỏ hơn cỡ đã chọn: giữ nguyên \(original), không phóng to."
        case .fourKForWeb: "4K thường quá lớn cho web; chỉ dùng khi cần phóng to hoặc in."
        case .largerThanSource(let percent):
            "File mới nặng hơn ảnh gốc \(percent)% (ảnh gốc đã tối ưu sẵn). Thử giảm chất lượng hoặc dùng luôn ảnh gốc."
        case .targetNotMet(let width?): "Không đạt giới hạn dung lượng ở cỡ này. Thử \(width) px."
        case .targetNotMet(nil): "Định dạng này không giảm được dung lượng. Chọn WebP hoặc JPEG để đạt giới hạn."
        case .animationDropped: "Ảnh động: định dạng này chỉ giữ khung hình đầu. Chọn GIF để giữ chuyển động."
        case .dimensionTooLarge(let max): "Ảnh quá lớn cho WebP (tối đa \(max) px mỗi cạnh). Chọn cỡ nhỏ hơn hoặc JPEG."
        }
    }

    static func error(_ error: ExportError) -> String {
        switch error {
        case .unreadable: "Không đọc được ảnh."
        case .iCloudNotDownloaded: "Ảnh trên iCloud chưa tải về được. Kiểm tra mạng rồi thử lại."
        case .permissionDenied: "Không có quyền ghi vào thư mục này."
        case .destinationExists: "Đã có file cùng tên."
        case .dimensionTooLarge(let max): "Ảnh quá lớn cho định dạng này (tối đa \(max) px)."
        case .encodeFailed: "Không tạo được file ảnh."
        case .diskFull: "Ổ đĩa đã đầy."
        case .cancelled: "Đã hủy."
        }
    }

    static func seo(_ item: SEOChecklist.Item) -> String {
        switch item {
        case .fileSize(let bytes): "Dung lượng \(Self.bytes(bytes)) (nên ≤ 200 KB)"
        case .dimensions(let edge): "Cạnh dài \(edge) px (nên ≤ 2560 px cho web)"
        case .name(_, false): "Tên file chưa có nghĩa: hãy mô tả nội dung ảnh"
        case .name(let words, true): words > 8 ? "Tên file dài \(words) từ (nên 2–8 từ)" : words < 2 ? "Tên file quá ngắn (nên 2–8 từ)" : "Tên file có nghĩa, \(words) từ"
        case .format(let format, let photo, let animated):
            switch format {
            case .webp, .jpeg: "Định dạng \(format.rawValue.uppercased()) phù hợp web"
            case .png: photo ? "PNG cho ảnh chụp: nặng, nên dùng WebP" : "PNG hợp với đồ họa, chữ"
            case .gif: animated ? "GIF động: cân nhắc video/WebP động" : "GIF tĩnh: nên dùng WebP"
            }
        case .metadataStripped: "Đã xóa EXIF, GPS (riêng tư + nhẹ hơn)"
        case .altText(let present): present ? "Có alt text" : "Chưa có alt text: điền ô Alt để dán vào website"
        }
    }
}
