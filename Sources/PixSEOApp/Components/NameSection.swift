import AppKit
import PixSEOCore
import SwiftUI

/// Name field(s), the final-name preview, suggestion chips and the alt-text row.
/// Used by the Quick Save panel and the editor's export bar.
struct NameSection: View {
    @Bindable var naming: FileNaming
    @Bindable var suggestions: SuggestionModel
    /// Final file name to show under the field.
    let preview: String
    var focus: FocusState<Bool>.Binding
    var showsAltText = true

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if naming.isBatch {
                Picker("Kiểu đặt tên", selection: $naming.usesSharedName) {
                    Text("Tên chung + số thứ tự").tag(true)
                    Text("Giữ tên riêng từng ảnh").tag(false)
                }
                .pickerStyle(.radioGroup).labelsHidden().horizontalRadioGroupLayout()
                if naming.usesSharedName {
                    TextField("vd: khai giảng k15", text: $naming.sharedName).focused(focus)
                }
            } else {
                TextField(placeholder, text: $naming.nameInput).focused(focus)
            }
            Text("→ \(preview)").font(.callout.monospaced()).foregroundStyle(.secondary)
                .lineLimit(1).truncationMode(.middle).textSelection(.enabled)
            if !naming.isBatch { chips }
            if showsAltText, !naming.isBatch { altRow }
        }
    }

    /// An auto-applied suggestion shows as the placeholder, so typing still replaces it.
    private var placeholder: String {
        if naming.sourceIsMeaningless, let best = suggestions.best { return "✨ \(best.title)" }
        return naming.namePlaceholder
    }

    @ViewBuilder private var chips: some View {
        HStack(spacing: 6) {
            if let ai = suggestions.ai { chip("✨ \(ai.slug)", help: "Gợi ý bằng AI trên máy", suggestion: ai) }
            if let fast = suggestions.heuristic, fast.slug != suggestions.ai?.slug {
                chip("🔤 \(fast.slug)", help: fast.source == .text ? "Từ chữ trong ảnh" : "Từ nội dung ảnh", suggestion: fast)
            }
            switch suggestions.aiState {
            case .running:
                ProgressView().controlSize(.small)
                Text("✨ Đang gợi ý…").font(.caption).foregroundStyle(.secondary)
            case .idle where suggestions.aiAvailable:
                Button("✨ Gợi ý bằng AI") { suggestions.requestAI(typed: naming.nameInput) }
                    .buttonStyle(.link).font(.caption)
            default:
                EmptyView()
            }
        }
    }

    private func chip(_ title: String, help: String, suggestion: NameSuggestion) -> some View {
        Button(title) {
            naming.nameInput = suggestion.title
            if suggestions.altText.isEmpty, let alt = suggestion.altText { suggestions.altText = alt }
        }
        .buttonStyle(.bordered).controlSize(.small).help("\(help). Bấm để dùng.")
    }

    private var altRow: some View {
        HStack {
            Text("Alt").foregroundStyle(.secondary).font(.callout)
            TextField("Mô tả ngắn cho người khiếm thị và Google (≤ 125 ký tự)", text: $suggestions.altText)
                .font(.callout)
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(suggestions.altText, forType: .string)
            } label: { Image(systemName: "doc.on.doc") }
                .buttonStyle(.borderless).help("Copy alt text").disabled(suggestions.altText.isEmpty)
        }
    }
}
