import PixSEOCore
import PixSEOShared
import SwiftUI

/// Width, format + quality, byte limit and PPI controls as `GridRow`s; place inside a `Grid`
/// so callers can add their own rows with matching label columns. `wide` uses segmented
/// controls (Quick Save panel); `compact` uses menus (the editor's narrow inspector).
struct ExportOptionControls: View {
    enum Layout { case wide, compact }

    @Bindable var options: ExportOptions
    var layout: Layout = .wide
    /// Hides the width (Open Graph fixes it).
    var widthLocked = false

    var body: some View {
        Group {
            GridRow {
                label("Chiều rộng")
                HStack {
                    Picker("Chiều rộng", selection: $options.widthChoice) {
                        ForEach(SizePresets.widths, id: \.self) { Text(verbatim: $0 == 3840 ? "4K" : "\($0)").tag($0) }
                        Text("Khác").tag(ExportOptions.customWidthTag)
                    }
                    .styled(layout).labelsHidden()
                    if options.widthChoice == ExportOptions.customWidthTag {
                        TextField("px", text: $options.customWidthText).frame(width: 64)
                    }
                }
                .disabled(widthLocked)
                .help(widthLocked ? "Tỉ lệ OG luôn xuất 1200×630" : "")
            }
            if layout == .compact {
                GridRow {
                    label("Tính theo")
                    Picker("Tính theo", selection: $options.resizeMode) {
                        Text("Chiều rộng").tag(ResizeMode.width)
                        Text("Cạnh dài").tag(ResizeMode.longEdge)
                        Text("Chiều cao").tag(ResizeMode.height)
                    }
                    .labelsHidden().disabled(widthLocked)
                }
            }
            GridRow {
                label("Định dạng")
                Picker("Định dạng", selection: $options.format) {
                    ForEach(OutputFormat.allCases, id: \.self) { Text($0.rawValue.uppercased()).tag($0) }
                }
                .styled(layout).labelsHidden().frame(maxWidth: layout == .wide ? 230 : .infinity)
            }
            if options.format.supportsQuality {
                GridRow {
                    label("Chất lượng")
                    HStack {
                        Slider(value: $options.quality, in: 0.4...1, step: 0.05) { Text("Chất lượng") }.labelsHidden()
                        Text("\(Int((options.quality * 100).rounded()))").monospacedDigit().frame(width: 28)
                    }
                }
            }
            GridRow {
                label("Dung lượng")
                HStack {
                    Picker("Dung lượng", selection: $options.targetKB) {
                        Text("Tự do").tag(Int?.none)
                        ForEach([100, 200, 300, 500], id: \.self) { Text("≤\($0)").tag(Int?.some($0)) }
                    }
                    .styled(layout).labelsHidden()
                    Text("KB").foregroundStyle(.secondary)
                }
            }
            GridRow {
                label("PPI")
                Picker("PPI", selection: $options.ppi) {
                    Text("72").tag(72)
                    Text("96").tag(96)
                }
                .pickerStyle(.segmented).labelsHidden().frame(width: 110)
                .disabled(!options.format.supportsPPI)
                .help("PPI chỉ là thông tin kèm theo; trình duyệt bỏ qua và dung lượng không đổi. WebP và GIF không lưu PPI.")
            }
            if layout == .compact {
                GridRow {
                    label("Làm nét")
                    Toggle("Làm nét nhẹ sau khi thu nhỏ", isOn: $options.sharpen).toggleStyle(.checkbox)
                }
            }
        }
    }

    private func label(_ text: String) -> some View { GridLabel(text) }
}

/// Right-aligned secondary label for the first column of a settings grid.
struct GridLabel: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text).foregroundStyle(.secondary).gridColumnAlignment(.trailing)
    }
}

private extension View {
    @ViewBuilder func styled(_ layout: ExportOptionControls.Layout) -> some View {
        if layout == .wide { pickerStyle(.segmented) } else { pickerStyle(.menu) }
    }
}
