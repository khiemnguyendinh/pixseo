import PixSEOCore
import PixSEOShared
import SwiftUI

/// Bottom bar of the editor: width and format, the live estimate, the file name and Save.
struct ExportBarView: View {
    @Bindable var model: EditorViewModel
    let onSave: (_ keepOpen: Bool) -> Void
    @FocusState private var nameFocused: Bool

    var body: some View {
        @Bindable var options = model.options
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Picker("Chiều rộng", selection: $options.widthChoice) {
                        ForEach(SizePresets.widths, id: \.self) { Text(verbatim: $0 == 3840 ? "4K" : "\($0) px").tag($0) }
                        Text("Khác…").tag(ExportOptions.customWidthTag)
                    }
                    .labelsHidden().frame(width: 110).disabled(model.aspect == .openGraph)
                    Picker("Định dạng", selection: $options.format) {
                        ForEach(OutputFormat.allCases, id: \.self) { Text($0.rawValue.uppercased()).tag($0) }
                    }
                    .labelsHidden().frame(width: 90)
                    if model.options.format.supportsQuality {
                        Text("\(Int((model.options.quality * 100).rounded()))").monospacedDigit().foregroundStyle(.secondary)
                            .help("Chất lượng — chỉnh ở tab Resize")
                    }
                }
                EstimateBadge(info: model.info, outputSize: model.outputSize, estimator: model.estimator,
                              checklist: model.checklist, note: model.isBatch ? "(ảnh đang xem)" : nil)
                if let advice = model.advice.first {
                    Label(UserFacingText.advice(advice), systemImage: "lightbulb").font(.callout).foregroundStyle(.orange)
                        .lineLimit(2)
                }
            }
            .frame(minWidth: 330, alignment: .leading)

            NameSection(naming: model.naming, suggestions: model.suggestions, preview: model.previewFileName, focus: $nameFocused)
                .frame(maxWidth: .infinity)

            VStack(alignment: .trailing, spacing: 8) {
                Button("Lưu") { onSave(false) }.keyboardShortcut(.defaultAction).disabled(!model.canSave)
                Button("Lưu, giữ cửa sổ") { onSave(true) }.keyboardShortcut(.return, modifiers: .option)
                    .disabled(!model.canSave).help("⌥⏎: lưu rồi xuất thêm cỡ hoặc định dạng khác")
            }
        }
    }
}
