import PixSEOCore
import PixSEOShared
import SwiftUI

/// Settings: General, Export & naming, Watermark, AI.
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsTab().tabItem { Label("Chung", systemImage: "gearshape") }
            ExportSettingsTab().tabItem { Label("Xuất & đặt tên", systemImage: "square.and.arrow.down") }
            WatermarkSettingsTab().tabItem { Label("Watermark", systemImage: "signature") }
            AISettingsTab().tabItem { Label("AI", systemImage: "sparkles") }
        }
        .padding(20)
        .frame(width: 560, height: 400)
    }
}

private struct GeneralSettingsTab: View {
    @Bindable private var store = SettingsStore.shared

    var body: some View {
        Form {
            ExtensionStatusView()
            Toggle("Hỏi tên file trước khi lưu", isOn: $store.preferences.askNameBeforeSave)
            Text("Tắt: chọn cỡ trong menu chuột phải là lưu luôn, đặt tên theo tên gốc.")
                .font(.callout).foregroundStyle(.secondary)
            Picker("Tự thoát khi không dùng", selection: $store.preferences.idleQuitMinutes) {
                Text("Không bao giờ").tag(0)
                ForEach([5, 15, 30, 60], id: \.self) { Text("Sau \($0) phút").tag($0) }
            }
            Text("PixSEO tự mở lại khi bạn chuột phải ảnh, nên thoát khi rảnh để tiết kiệm RAM.")
                .font(.callout).foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }
}

private struct ExportSettingsTab: View {
    @Bindable private var store = SettingsStore.shared

    var body: some View {
        Form {
            Picker("Định dạng", selection: $store.preferences.format) {
                ForEach(OutputFormat.allCases, id: \.self) { Text($0.rawValue.uppercased()).tag($0) }
            }
            Picker("Chiều rộng mặc định", selection: $store.preferences.width) {
                ForEach(SizePresets.widths, id: \.self) { Text(verbatim: $0 == 3840 ? "4K · 3840 px" : "\($0) px").tag($0) }
            }
            Picker("Kích thước tính theo", selection: $store.preferences.resizeMode) {
                Text("Chiều rộng").tag(ResizeMode.width)
                Text("Cạnh dài").tag(ResizeMode.longEdge)
                Text("Chiều cao").tag(ResizeMode.height)
            }
            LabeledContent("Chất lượng") {
                Slider(value: $store.preferences.quality, in: 0.4...1, step: 0.05)
                Text("\(Int((store.preferences.quality * 100).rounded()))").monospacedDigit().frame(width: 28)
            }
            Picker("PPI", selection: $store.preferences.ppi) {
                Text("72").tag(72)
                Text("96").tag(96)
            }
            Toggle("Làm nét nhẹ sau khi thu nhỏ", isOn: $store.preferences.sharpen)
            Picker("Hậu tố kích thước trong tên", selection: $store.preferences.sizeSuffix) {
                Text("Chiều rộng (…-1920)").tag(SizeSuffix.width)
                Text("Cạnh dài (…-1920)").tag(SizeSuffix.longEdge)
                Text("Rộng×cao (…-1920x1080)").tag(SizeSuffix.dimensions)
                Text("Không thêm").tag(SizeSuffix.none)
            }
        }
        .formStyle(.grouped)
    }
}

private struct WatermarkSettingsTab: View {
    @State private var presets = SettingsStore.shared.watermarkPresets.presets
    @State private var defaultID = SettingsStore.shared.watermarkPresets.defaultID
    private var store: WatermarkPresetStore { SettingsStore.shared.watermarkPresets }

    var body: some View {
        Form {
            if presets.isEmpty {
                Text("Chưa có preset. Mở Quick Watermark, chỉnh chữ hoặc logo rồi bấm “Lưu preset…”.")
                    .foregroundStyle(.secondary)
            }
            ForEach(presets) { preset in
                HStack {
                    Image(systemName: preset.id == defaultID ? "star.fill" : "star").foregroundStyle(.yellow)
                        .onTapGesture { try? store.setDefault(preset.id); reload() }
                        .help("Đặt làm mặc định cho Quick Watermark")
                    Text(preset.name)
                    Spacer()
                    Button("Xóa", role: .destructive) { try? store.delete(preset.id); reload() }
                }
            }
        }
        .formStyle(.grouped)
    }

    private func reload() {
        presets = store.presets
        defaultID = store.defaultID
    }
}

private struct AISettingsTab: View {
    @Bindable private var store = SettingsStore.shared

    var body: some View {
        Form {
            Toggle("Gợi ý tên file và alt text bằng AI trên máy", isOn: $store.preferences.aiEnabled)
            LabeledContent("Apple Intelligence") { Text(statusText).foregroundStyle(.secondary) }
            TextField("Ngữ cảnh thương hiệu", text: $store.preferences.brandContext,
                      prompt: Text("vd: Kstudy Academy, đào tạo AI và marketing"))
            Text("Giúp AI dùng đúng tên thương hiệu và từ khóa. Ảnh không rời khỏi máy.")
                .font(.callout).foregroundStyle(.secondary)
            Toggle("Tự copy alt text sau khi lưu", isOn: $store.preferences.autoCopyAlt)
        }
        .formStyle(.grouped)
    }

    private var statusText: String {
        switch OnDeviceNameSuggester.status {
        case .available: "Sẵn sàng"
        case .unsupported: "Cần macOS 26 và chip Apple — dùng gợi ý từ chữ trong ảnh"
        case .unavailable: "Chưa bật hoặc đang tải — bật trong Cài đặt hệ thống › Apple Intelligence"
        }
    }
}
