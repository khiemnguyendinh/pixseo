import SwiftUI

struct ToastView: View {
    let model: ToastModel
    let onClose: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            icon.font(.title2)
            VStack(alignment: .leading, spacing: 4) {
                Text(model.title).font(.headline).lineLimit(2)
                if let detail = model.detail {
                    Text(detail).font(.callout).foregroundStyle(.secondary).lineLimit(2)
                }
                if !model.actions.isEmpty {
                    HStack {
                        ForEach(model.actions) { action in
                            Button(action.title) { action.perform() }.controlSize(.small)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
            Button(action: onClose) { Image(systemName: "xmark") }
                .buttonStyle(.plain).foregroundStyle(.secondary).accessibilityLabel("Đóng")
        }
        .padding(14)
        .frame(width: 420, height: 92, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .onHover { model.isHovered = $0 }
    }

    @ViewBuilder private var icon: some View {
        switch model.style {
        case .progress: ProgressView().controlSize(.small)
        case .success: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .warning: Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
        case .failure: Image(systemName: "xmark.octagon.fill").foregroundStyle(.red)
        }
    }
}
