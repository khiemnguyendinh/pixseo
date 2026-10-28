import PixSEOCore
import SwiftUI

/// Ratio presets, orientation swap, rotate/flip, fit-to-subject and reset.
struct CropInspectorView: View {
    @Bindable var model: EditorViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Tỉ lệ").font(.headline)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(AspectRatioPreset.allCases.filter { $0 != .openGraph }, id: \.self) { preset in
                    ratioButton(preset)
                }
            }
            ratioButton(.openGraph).help("Ảnh chia sẻ link (Facebook, Zalo…): luôn xuất đúng 1200×630")

            HStack {
                Button { model.aspectSwapped.toggle() } label: { Label("Đổi chiều", systemImage: "arrow.left.arrow.right") }
                    .disabled(!model.aspect.canSwapOrientation)
                Spacer()
                Button { model.rotate(clockwise: false) } label: { Image(systemName: "rotate.left") }.help("Xoay trái 90°")
                Button { model.rotate(clockwise: true) } label: { Image(systemName: "rotate.right") }.help("Xoay phải 90°")
                Button { model.flip() } label: { Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right") }
                    .help("Lật ngang")
            }

            Button { model.placeOnSubject() } label: { Label("Căn theo chủ thể", systemImage: "viewfinder") }
                .disabled(model.aspect == .free)
                .help("Đặt khung đúng tỉ lệ quanh khuôn mặt hoặc chủ thể chính")
            Button(role: .destructive) { model.resetCrop() } label: { Label("Đặt lại ảnh này", systemImage: "arrow.counterclockwise") }

            Divider()
            Text("Kéo khung hoặc tay nắm để chỉnh. Phím mũi tên dịch 1 px, giữ ⇧ dịch 10 px.")
                .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            if model.isBatch {
                Text("Tỉ lệ áp cho cả \(model.files.count) ảnh; mỗi ảnh tự căn theo chủ thể. Ảnh nào chỉnh tay có chấm xanh ở dải ảnh bên dưới.")
                    .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func ratioButton(_ preset: AspectRatioPreset) -> some View {
        let selected = model.aspect == preset
        return Button { model.aspect = preset } label: {
            Text(preset.label).frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(selected ? .accentColor : nil)
        .background(selected ? Color.accentColor.opacity(0.18) : .clear, in: RoundedRectangle(cornerRadius: 6))
    }
}

/// Export choices in full, for the Resize tab.
struct ResizeInspectorView: View {
    @Bindable var model: EditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Kích thước & định dạng").font(.headline)
            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
                ExportOptionControls(options: model.options, layout: .compact, widthLocked: model.aspect == .openGraph)
            }
            if let size = model.outputSize {
                Text("Ảnh ra: \(size.description) px").font(.callout).foregroundStyle(.secondary)
            }
            ForEach(model.advice, id: \.self) { advice in
                Label(UserFacingText.advice(advice), systemImage: "lightbulb")
                    .font(.callout).foregroundStyle(.orange).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
