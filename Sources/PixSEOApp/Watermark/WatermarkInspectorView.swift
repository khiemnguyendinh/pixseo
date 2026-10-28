import AppKit
import PixSEOCore
import SwiftUI

/// Text or logo watermark: content, font, color, size, opacity, position and advanced options.
struct WatermarkInspectorView: View {
    @Bindable var model: EditorViewModel
    @State private var lastText = "© "
    @State private var showsAdvanced = false
    private let fonts = FontCatalog.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Chèn watermark", isOn: $model.watermarkEnabled).toggleStyle(.switch).font(.headline)
            if model.watermarkEnabled {
                WatermarkPresetBar(model: model)
                Picker("Loại", selection: isLogo) {
                    Text("Chữ").tag(false)
                    Text("Logo").tag(true)
                }
                .pickerStyle(.segmented).labelsHidden()
                if case .text = model.watermark.kind { textControls } else { logoControls }
                slider("Kích thước", value: $model.watermark.widthFraction, range: 0.03...0.6)
                slider("Độ mờ", value: $model.watermark.opacity, range: 0.1...1)
                positionGrid
                DisclosureGroup("Nâng cao", isExpanded: $showsAdvanced) { advanced }
            }
        }
        .onAppear { fonts.load() }
    }

    private var isLogo: Binding<Bool> {
        Binding(get: { if case .logo = model.watermark.kind { true } else { false } },
                set: { logo in
                    if logo {
                        if case .text(let text) = model.watermark.kind { lastText = text }
                        chooseLogo()
                    } else {
                        model.watermark.kind = .text(lastText)
                    }
                })
    }

    private var text: Binding<String> {
        Binding(get: { if case .text(let text) = model.watermark.kind { text } else { "" } },
                set: { model.watermark.kind = .text($0) })
    }

    @ViewBuilder private var textControls: some View {
        TextField("© Tên thương hiệu", text: text)
        HStack {
            Menu(model.watermark.fontName) {
                if !fonts.recent.isEmpty {
                    Section("Gần đây") { ForEach(fonts.recent, id: \.self, content: fontButton) }
                }
                Section("Có dấu tiếng Việt") { ForEach(fonts.vietnamese, id: \.self, content: fontButton) }
                Section("Thiếu dấu tiếng Việt") {
                    ForEach(fonts.missingDiacritics, id: \.self) { Text("\($0) — thiếu dấu") }
                }
            }
            Toggle("Đậm", isOn: $model.watermark.bold).toggleStyle(.checkbox)
        }
        HStack(spacing: 8) {
            swatch(.white)
            swatch(.black)
            ColorPicker("Màu", selection: color, supportsOpacity: false).labelsHidden()
                .help("Bảng màu có công cụ hút màu (lấy màu thương hiệu từ logo trên màn hình)")
            Text("Màu chữ").foregroundStyle(.secondary).font(.callout)
        }
    }

    private func fontButton(_ family: String) -> some View {
        Button(family) {
            model.watermark.fontName = family
            fonts.noteUsed(family)
        }
    }

    @ViewBuilder private var logoControls: some View {
        Button("Chọn logo…", action: chooseLogo)
        if case .logo(let path) = model.watermark.kind, ["jpg", "jpeg"].contains(URL(fileURLWithPath: path).pathExtension.lowercased()) {
            Label("Logo nên là PNG nền trong suốt", systemImage: "lightbulb").font(.callout).foregroundStyle(.orange)
        }
    }

    private var positionGrid: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Vị trí").foregroundStyle(.secondary).font(.callout)
            HStack(alignment: .top, spacing: 12) {
                Grid(horizontalSpacing: 4, verticalSpacing: 4) {
                    ForEach(0..<3) { row in
                        GridRow {
                            ForEach(0..<3) { column in
                                let anchor = WatermarkAnchor.allCases[row * 3 + column]
                                Button { model.watermark.anchor = anchor; model.watermark.offset = .zero; model.watermark.autoCorner = false } label: {
                                    Image(systemName: model.watermark.anchor == anchor && !model.watermark.autoCorner ? "circle.fill" : "circle")
                                        .frame(width: 18, height: 18)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
                Toggle("Tự chọn góc trống", isOn: $model.watermark.autoCorner).toggleStyle(.checkbox)
                    .help("Mỗi ảnh tự đặt watermark vào góc ít chi tiết nhất")
            }
        }
    }

    @ViewBuilder private var advanced: some View {
        VStack(alignment: .leading, spacing: 10) {
            slider("Xoay", value: $model.watermark.rotationDegrees, range: -45...45, format: { "\(Int($0))°" })
            Picker("Độ đọc", selection: $model.watermark.legibility) {
                Text("Tự động").tag(WatermarkLegibility.auto)
                Text("Viền").tag(WatermarkLegibility.outline)
                Text("Bóng").tag(WatermarkLegibility.shadow)
                Text("Không").tag(WatermarkLegibility.none)
            }
            slider("Lề", value: $model.watermark.marginFraction, range: 0...0.1)
        }
        .padding(.top, 6)
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>,
                        format: @escaping (Double) -> String = { "\(Int(($0 * 100).rounded()))%" }) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary).font(.callout).frame(width: 72, alignment: .leading)
            Slider(value: value, in: range)
            Text(format(value.wrappedValue)).monospacedDigit().font(.callout).frame(width: 40, alignment: .trailing)
        }
    }

    private func swatch(_ rgba: RGBAColor) -> some View {
        Button { model.watermark.color = rgba } label: {
            Circle().fill(Color(cgColor: rgba.cgColor)).frame(width: 18, height: 18)
                .overlay(Circle().stroke(model.watermark.color == rgba ? Color.accentColor : .secondary, lineWidth: model.watermark.color == rgba ? 2 : 0.5))
        }
        .buttonStyle(.plain)
    }

    private var color: Binding<Color> {
        Binding(get: { Color(cgColor: model.watermark.color.cgColor) },
                set: { newValue in
                    guard let c = NSColor(newValue).usingColorSpace(.sRGB) else { return }
                    model.watermark.color = RGBAColor(red: c.redComponent, green: c.greenComponent, blue: c.blueComponent)
                })
    }

    private func chooseLogo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .heic, .webP, .tiff]
        panel.prompt = "Dùng làm logo"
        guard panel.runModal() == .OK, let url = panel.url,
              let path = try? SettingsStore.shared.watermarkPresets.importLogo(from: url) else { return }
        model.watermark.kind = .logo(path: path)
    }
}
