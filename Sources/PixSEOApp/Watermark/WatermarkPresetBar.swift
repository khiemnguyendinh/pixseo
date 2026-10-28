import PixSEOCore
import SwiftUI

/// Apply, save, rename, delete and set the default watermark preset.
struct WatermarkPresetBar: View {
    @Bindable var model: EditorViewModel
    @State private var presets = SettingsStore.shared.watermarkPresets.presets
    @State private var naming: NamingTarget?
    @State private var nameText = ""

    private enum NamingTarget: Identifiable {
        case new, rename(UUID)
        var id: String { if case .rename(let id) = self { id.uuidString } else { "new" } }
    }

    private var store: WatermarkPresetStore { SettingsStore.shared.watermarkPresets }

    var body: some View {
        HStack {
            Menu("Preset") {
                if presets.isEmpty { Text("Chưa có preset") }
                ForEach(presets) { preset in
                    Button(preset.id == store.defaultID ? "\(preset.name) (mặc định)" : preset.name) { model.watermark = preset.spec }
                }
                if !presets.isEmpty {
                    Divider()
                    Menu("Quản lý") {
                        ForEach(presets) { preset in
                            Menu(preset.name) {
                                Button("Đặt làm mặc định") { try? store.setDefault(preset.id); reload() }
                                Button("Đổi tên…") { nameText = preset.name; naming = .rename(preset.id) }
                                Button("Xóa", role: .destructive) { try? store.delete(preset.id); reload() }
                            }
                        }
                    }
                }
            }
            .fixedSize()
            Button("Lưu preset…") { nameText = ""; naming = .new }
                .disabled(model.watermark.isEmpty)
        }
        .alert(alertTitle, isPresented: Binding(get: { naming != nil }, set: { if !$0 { naming = nil } })) {
            TextField("vd: Logo góc phải", text: $nameText)
            Button("Lưu") { commitName() }
            Button("Hủy", role: .cancel) { naming = nil }
        }
    }

    private var alertTitle: String {
        if case .rename = naming { return "Đổi tên preset" }
        return "Lưu watermark thành preset"
    }

    private func commitName() {
        let name = nameText.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, let target = naming else { return }
        switch target {
        case .new: try? store.save(WatermarkPreset(name: name, spec: model.watermark))
        case .rename(let id): try? store.rename(id, to: name)
        }
        naming = nil
        reload()
    }

    private func reload() {
        presets = store.presets
    }
}
