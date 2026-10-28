import PixSEOCore
import SwiftUI

/// Editor window: top bar with batch navigation and tabs, canvas + inspector, filmstrip for
/// batches, and the export bar.
struct EditorView: View {
    @Bindable var model: EditorViewModel
    let onSave: (_ keepOpen: Bool) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            topBar.padding(.horizontal, 14).padding(.vertical, 8)
            Divider()
            HStack(spacing: 0) {
                canvas.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.black.opacity(0.85))
                Divider()
                ScrollView { inspector.padding(16) }.frame(width: 310)
            }
            if model.isBatch {
                Divider()
                FilmstripView(model: model).frame(height: 76)
            }
            Divider()
            ExportBarView(model: model, onSave: onSave).padding(14)
        }
        .background(shortcuts)
        .onChange(of: model.options.fingerprint) { model.estimator.schedule(model.estimateKey) }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            if model.isBatch {
                Button { model.previous() } label: { Image(systemName: "chevron.left") }
                    .keyboardShortcut(.leftArrow, modifiers: .command).disabled(model.index == 0)
                Text("\(model.index + 1)/\(model.files.count)").monospacedDigit()
                Button { model.next() } label: { Image(systemName: "chevron.right") }
                    .keyboardShortcut(.rightArrow, modifiers: .command).disabled(model.index + 1 >= model.files.count)
            }
            Text(model.current.lastPathComponent).font(.headline).lineLimit(1).truncationMode(.middle)
            Spacer()
            Picker("Chế độ", selection: $model.tab) {
                ForEach(EditorTab.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented).labelsHidden().frame(width: 300)
        }
    }

    @ViewBuilder private var canvas: some View {
        switch model.tab {
        case .crop:
            if let image = model.orientedPreview { CropOverlayView(model: model, image: image) } else { loading }
        case .watermark:
            if let image = model.finalPreview { WatermarkOverlayView(model: model, image: image) } else { loading }
        case .resize:
            if let image = model.finalPreview {
                Image(decorative: image, scale: 1).resizable().scaledToFit().padding(24)
            } else { loading }
        }
    }

    private var loading: some View {
        ProgressView().controlSize(.large).frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder private var inspector: some View {
        switch model.tab {
        case .resize: ResizeInspectorView(model: model)
        case .crop: CropInspectorView(model: model)
        case .watermark: WatermarkInspectorView(model: model)
        }
    }

    /// ⌘1/2/3 switch tabs, Esc closes. Invisible buttons carry the shortcuts.
    private var shortcuts: some View {
        ZStack {
            ForEach(EditorTab.allCases, id: \.self) { tab in
                Button("") { model.tab = tab }.keyboardShortcut(KeyEquivalent(Character("\(tab.rawValue + 1)")), modifiers: .command)
            }
            Button("", action: onClose).keyboardShortcut(.cancelAction)
        }
        .opacity(0).frame(width: 0, height: 0).allowsHitTesting(false)
    }
}

/// Thumbnails of the batch; a dot marks images whose crop was adjusted by hand.
struct FilmstripView: View {
    @Bindable var model: EditorViewModel
    @State private var thumbnails: [URL: CGImage] = [:]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 8) {
                    ForEach(Array(model.files.enumerated()), id: \.offset) { index, url in
                        Button { model.index = index } label: { cell(url, selected: index == model.index) }
                            .buttonStyle(.plain).id(index)
                            .task { await loadThumbnail(url) }
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
            }
            .onChange(of: model.index) { proxy.scrollTo(model.index, anchor: .center) }
        }
    }

    private func cell(_ url: URL, selected: Bool) -> some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let image = thumbnails[url] { Image(decorative: image, scale: 1).resizable().scaledToFill() } else { Color.secondary.opacity(0.2) }
            }
            .frame(width: 72, height: 56).clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(selected ? Color.accentColor : .clear, lineWidth: 2.5))
            if model.edits[url]?.manual == true {
                Circle().fill(.green).frame(width: 9, height: 9).padding(3)
            }
        }
    }

    private func loadThumbnail(_ url: URL) async {
        guard thumbnails[url] == nil else { return }
        let image = await Task.detached(priority: .utility) { try? ImageSourceReader.preview(url, maxLongEdge: 160) }.value
        thumbnails[url] = image
    }
}
