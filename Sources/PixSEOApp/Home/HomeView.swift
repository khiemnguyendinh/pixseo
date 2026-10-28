import AppKit
import FinderSync
import SwiftUI
import UniformTypeIdentifiers

/// Shown when PixSEO is opened directly: a drop zone, whether the Finder menu is on, and a
/// three-step guide on first run.
struct HomeView: View {
    let onFiles: ([URL]) -> Void
    let onSettings: () -> Void
    @Bindable private var settings = SettingsStore.shared
    @State private var isTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            dropZone
            ExtensionStatusView()
            if !settings.preferences.onboardingDone { onboarding }
            HStack(alignment: .top) {
                Text("Chuột phải ảnh trong Finder → Quick Resize, Quick Crop, Quick Watermark.")
                    .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                Spacer()
                Button("Cài đặt…", action: onSettings)
            }
        }
        .padding(22)
        .frame(width: 520)
    }

    private var dropZone: some View {
        VStack(spacing: 10) {
            Image(systemName: "photo.on.rectangle.angled").font(.system(size: 34)).foregroundStyle(.secondary)
            HStack(spacing: 4) {
                Text("Kéo ảnh vào đây · hoặc")
                Button("Chọn ảnh…", action: choose).buttonStyle(.link)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(RoundedRectangle(cornerRadius: 12).fill(isTargeted ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(isTargeted ? Color.accentColor : .secondary.opacity(0.4),
                                                           style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])))
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            Task {
                var urls: [URL] = []
                for provider in providers {
                    if let url = try? await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) as? Data,
                       let file = URL(dataRepresentation: url, relativeTo: nil) { urls.append(file) }
                }
                await MainActor.run { onFiles(urls) }
            }
            return true
        }
    }

    private var onboarding: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bắt đầu trong 2 phút").font(.headline)
            step(1, "Bật menu chuột phải (ô phía trên). Nếu chưa bật, bấm “Bật ngay” rồi tích PixSEO trong mục Finder.")
            step(2, "Lần đầu lưu ảnh ở Desktop, Tài liệu hoặc Tải về, macOS sẽ hỏi quyền: hãy chọn Cho phép.")
            step(3, "Thử ngay: bấm Chọn ảnh… ở trên, hoặc chuột phải một ảnh trong Finder → Quick Resize → 1920 px.")
            Button("Đã hiểu, ẩn hướng dẫn") { settings.preferences.onboardingDone = true }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.accentColor.opacity(0.07)))
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number)").font(.callout.bold()).frame(width: 20, height: 20).background(Circle().fill(Color.accentColor.opacity(0.2)))
            Text(text).font(.callout).fixedSize(horizontal: false, vertical: true)
        }
    }

    private func choose() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.image]
        panel.prompt = "Chọn"
        if panel.runModal() == .OK { onFiles(panel.urls) }
    }
}

/// "Menu chuột phải đang bật" or a button to the system page that enables it. Re-checks every
/// second so it flips as soon as the user ticks the box.
struct ExtensionStatusView: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            let enabled = FIFinderSyncController.isExtensionEnabled
            HStack {
                Label(enabled ? "Menu chuột phải đang bật" : "Menu chuột phải chưa bật",
                      systemImage: enabled ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(enabled ? .green : .orange)
                if !enabled {
                    Spacer()
                    Button("Bật ngay") { FIFinderSyncController.showExtensionManagementInterface() }
                        .help("Mở Cài đặt hệ thống › Mục đăng nhập & Tiện ích mở rộng › Finder")
                }
            }
        }
    }
}
