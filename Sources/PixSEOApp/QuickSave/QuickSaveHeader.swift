import PixSEOCore
import SwiftUI

/// Thumbnail, source details, the live "before → after" estimate and the SEO check.
struct QuickSaveHeader: View {
    let model: QuickSaveViewModel

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Group {
                if let thumbnail = model.thumbnail {
                    Image(decorative: thumbnail, scale: 1).resizable().scaledToFill()
                } else {
                    Color.secondary.opacity(0.15)
                }
            }
            .frame(width: 64, height: 48).clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                Text(model.isBatch ? "\(model.files.count) ảnh" : model.files.first?.lastPathComponent ?? "")
                    .font(.headline).lineLimit(1).truncationMode(.middle)
                EstimateBadge(info: model.firstInfo, outputSize: model.outputSize, estimator: model.estimator,
                              checklist: model.checklist, note: model.isBatch ? "(ảnh đầu)" : nil)
            }
        }
    }
}
