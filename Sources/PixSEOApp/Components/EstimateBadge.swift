import PixSEOCore
import SwiftUI

/// "6000×4000 · 4.2 MB → 1920×1280 · ~186 KB −96% ● SEO ✓". The SEO pill opens a checklist.
struct EstimateBadge: View {
    let info: SourceImageInfo?
    let outputSize: PixelSize?
    let estimator: SizeEstimator
    let checklist: SEOChecklist?
    var note: String?
    @State private var showsChecklist = false

    var body: some View {
        HStack(spacing: 6) {
            if let info { Text("\(info.pixelSize.description) · \(UserFacingText.bytes(info.byteCount))") }
            Image(systemName: "arrow.right")
            if let outputSize { Text(outputSize.description) }
            estimate
            if let note { Text(note) }
            if let checklist { seoPill(checklist) }
        }
        .font(.callout).foregroundStyle(.secondary)
    }

    @ViewBuilder private var estimate: some View {
        if estimator.isEstimating {
            ProgressView().controlSize(.small)
        } else if let output = estimator.output {
            Text("· ~\(UserFacingText.bytes(output.data.count))")
            Text(UserFacingText.savings(from: output.sourceBytes, to: output.data.count))
                .foregroundStyle(output.data.count <= output.sourceBytes ? .green : .orange)
            Circle().fill(Self.color(ExportAdvisor.sizeBadge(bytes: output.data.count))).frame(width: 8, height: 8)
                .help("Xanh ≤ 200 KB · Vàng ≤ 500 KB · Đỏ > 500 KB")
        } else if let error = estimator.error {
            Text("· " + UserFacingText.error(error)).foregroundStyle(.red)
        }
    }

    private func seoPill(_ checklist: SEOChecklist) -> some View {
        let issues = checklist.issues.count
        return Button(issues == 0 ? "SEO ✓" : "SEO ⚠ \(issues)") { showsChecklist.toggle() }
            .buttonStyle(.bordered).controlSize(.small)
            .tint(issues == 0 ? .green : checklist.worst == .poor ? .red : .orange)
            .popover(isPresented: $showsChecklist, arrowEdge: .bottom) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Kiểm tra SEO ảnh").font(.headline)
                    ForEach(Array(checklist.entries.enumerated()), id: \.offset) { _, entry in
                        Label(UserFacingText.seo(entry.item), systemImage: entry.level == .good ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(entry.level == .good ? .green : entry.level == .fair ? .orange : .red)
                    }
                }
                .padding(14).frame(width: 360, alignment: .leading)
            }
    }

    static func color(_ badge: ExportAdvisor.SizeBadge) -> Color {
        switch badge {
        case .good: .green
        case .fair: .yellow
        case .heavy: .red
        }
    }
}
