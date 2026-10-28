import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Everything the name suggester may use. The model only sees text, never the picture.
public struct SuggestionInput: Sendable {
    public var fileName: String
    public var analysis: ContentAnalysis
    public var brandContext: String
    /// What the user already typed, used as a hint.
    public var typed: String

    public init(fileName: String, analysis: ContentAnalysis, brandContext: String = "", typed: String = "") {
        self.fileName = fileName
        self.analysis = analysis
        self.brandContext = brandContext
        self.typed = typed
    }

    /// The prompt, in Vietnamese. OCR text is capped at 500 characters.
    var prompt: String {
        let text = analysis.lines.map(\.text).joined(separator: " | ")
        var parts = ["Tên file gốc: \(fileName)",
                     "Chữ trong ảnh (OCR): \(text.isEmpty ? "(không có)" : String(text.prefix(500)))",
                     "Nhãn nội dung: \(analysis.labels.isEmpty ? "(không có)" : analysis.labels.joined(separator: ", "))"]
        if analysis.faceCount > 0 { parts.append("Số khuôn mặt: \(analysis.faceCount)") }
        if !brandContext.isEmpty { parts.append("Ngữ cảnh thương hiệu: \(brandContext)") }
        if !typed.isEmpty { parts.append("Người dùng đã gõ: \(typed)") }
        return parts.joined(separator: "\n")
    }
}

/// Whether Apple's on-device model can be used here, and why not.
public enum OnDeviceAIStatus: Sendable, Equatable {
    case available
    /// macOS older than 26 or an Intel Mac.
    case unsupported
    /// Apple Intelligence is off, still downloading, or the device isn't eligible.
    case unavailable(String)
}

/// Suggests a Vietnamese title + alt text with Apple's on-device Foundation Model (macOS 26).
/// Free, offline, ~10 s per image, so it only runs automatically for one meaningless name.
public enum OnDeviceNameSuggester {
    static let instructions = """
    Bạn là chuyên gia SEO hình ảnh cho website tiếng Việt. Chỉ dùng thông tin được cung cấp, không bịa thêm. \
    Trả lời bằng tiếng Việt có dấu.
    """

    public static var status: OnDeviceAIStatus {
        #if canImport(FoundationModels)
        if #available(macOS 26, *) {
            switch SystemLanguageModel.default.availability {
            case .available: return .available
            case .unavailable(let reason): return .unavailable(String(describing: reason))
            }
        }
        #endif
        return .unsupported
    }

    /// Returns `nil` when unavailable, refused by guardrails, timed out (20 s) or invalid.
    public static func suggest(_ input: SuggestionInput, timeout: Duration = .seconds(20)) async -> NameSuggestion? {
        #if canImport(FoundationModels)
        if #available(macOS 26, *), status == .available {
            return await withTaskGroup(of: NameSuggestion?.self) { group in
                group.addTask { try? await generate(input) }
                group.addTask { try? await Task.sleep(for: timeout); return nil }
                let first = await group.next() ?? nil
                group.cancelAll()
                return first
            }
        }
        #endif
        return nil
    }

    #if canImport(FoundationModels)
    @available(macOS 26, *)
    private static func generate(_ input: SuggestionInput) async throws -> NameSuggestion? {
        // DynamicGenerationSchema instead of @Generable: the macro plugin isn't in Command Line Tools.
        func property(_ name: String, _ description: String) -> DynamicGenerationSchema.Property {
            DynamicGenerationSchema.Property(name: name, description: description, schema: DynamicGenerationSchema(type: String.self))
        }
        let schema = try GenerationSchema(root: DynamicGenerationSchema(name: "ImageSEO", properties: [
            property("title", "Tiêu đề tiếng Việt có dấu, 3 đến 7 từ, chứa từ khóa chính của ảnh"),
            property("altText", "Đúng 1 câu tiếng Việt có dấu, tối đa 125 ký tự, mô tả nội dung và ngữ cảnh ảnh, không mở đầu bằng 'Hình ảnh của'"),
        ]), dependencies: [])
        let session = LanguageModelSession(instructions: instructions)
        let options = GenerationOptions(temperature: 0.2, maximumResponseTokens: 120)
        let response = try await session.respond(to: input.prompt, schema: schema, options: options)
        let title = try response.content.value(String.self, forProperty: "title")
        let alt = try? response.content.value(String.self, forProperty: "altText")
        return NameSuggestion.validated(title: title, altText: alt, source: .onDevice)
    }
    #endif
}
