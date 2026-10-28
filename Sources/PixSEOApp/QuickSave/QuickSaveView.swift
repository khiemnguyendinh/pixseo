import PixSEOCore
import SwiftUI

/// The Quick Save panel: size, format, byte limit, PPI, watermark and file name, with a live
/// size estimate and SEO check.
struct QuickSaveView: View {
    @Bindable var model: QuickSaveViewModel
    let onCancel: () -> Void
    let onSave: () -> Void
    let onOpenEditor: () -> Void
    @FocusState private var nameFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            QuickSaveHeader(model: model)
            Divider()
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {
                ExportOptionControls(options: model.options)
                if !model.watermarkPresets.isEmpty {
                    GridRow {
                        GridLabel("Watermark")
                        Picker("Watermark", selection: $model.watermarkID) {
                            Text("Không").tag(UUID?.none)
                            ForEach(model.watermarkPresets) { Text($0.name).tag(UUID?.some($0.id)) }
                        }
                        .labelsHidden().frame(maxWidth: 260)
                    }
                }
                GridRow(alignment: .firstTextBaseline) {
                    GridLabel("Tên file")
                    NameSection(naming: model.naming, suggestions: model.suggestions,
                                preview: model.previewFileName, focus: $nameFocused)
                }
            }
            ForEach(model.advice, id: \.self) { advice in
                Label(UserFacingText.advice(advice), systemImage: "lightbulb")
                    .font(.callout).foregroundStyle(.orange)
            }
            if !model.skipped.isEmpty {
                Text("Bỏ qua \(model.skipped.count) file không đọc được.").font(.callout).foregroundStyle(.secondary)
            }
            HStack {
                Button("Mở Editor", action: onOpenEditor).keyboardShortcut("e", modifiers: .command)
                    .help("Crop, watermark và xem trước lớn (⌘E)")
                Spacer()
                Button("Hủy", action: onCancel).keyboardShortcut(.cancelAction)
                Button("Lưu", action: onSave).keyboardShortcut(.defaultAction).disabled(!model.canSave)
            }
        }
        .padding(20)
        .frame(width: 600)
        .onAppear { nameFocused = true }
        .onChange(of: model.options.fingerprint) { model.scheduleEstimate() }
        .onChange(of: model.watermarkID) { model.scheduleEstimate() }
    }
}
