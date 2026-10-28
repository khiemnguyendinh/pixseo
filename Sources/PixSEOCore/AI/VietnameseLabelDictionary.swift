/// Vietnamese words for the Vision scene labels most common in business, event and course
/// photos. Labels not listed are ignored rather than guessed.
public enum VietnameseLabelDictionary {
    private static let words: [String: String] = [
        "people": "mọi người", "adult": "người lớn", "child": "trẻ em", "baby": "em bé", "crowd": "đám đông",
        "group": "nhóm", "portrait": "chân dung", "selfie": "ảnh tự chụp", "wedding": "đám cưới",
        "ceremony": "buổi lễ", "celebration": "lễ kỷ niệm", "party": "tiệc", "concert": "hòa nhạc",
        "stage": "sân khấu", "auditorium": "hội trường", "conference": "hội nghị", "meeting": "cuộc họp",
        "classroom": "lớp học", "office": "văn phòng", "computer": "máy tính", "laptop": "máy tính xách tay",
        "document": "tài liệu", "poster": "áp phích", "screenshot": "ảnh chụp màn hình", "food": "món ăn",
        "drink": "đồ uống", "coffee": "cà phê", "restaurant": "nhà hàng", "beach": "bãi biển", "sea": "biển",
        "mountain": "núi", "sky": "bầu trời", "sunset": "hoàng hôn", "tree": "cây xanh", "flower": "hoa",
        "garden": "khu vườn", "city": "thành phố", "building": "tòa nhà", "street": "đường phố",
        "car": "ô tô", "motorcycle": "xe máy", "dog": "chó", "cat": "mèo", "spa": "spa",
        "cosmetics": "mỹ phẩm", "sport": "thể thao", "graduation": "lễ tốt nghiệp", "book": "sách",
    ]

    public static func word(for label: String) -> String? {
        words[label.lowercased()]
    }
}
