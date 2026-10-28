import Foundation

/// Turns a selection of images plus the user's naming choice into export jobs, each saved next
/// to its source under a collision-free SEO name.
public enum ExportPlanner {
    /// - Parameters:
    ///   - singleName: what the user typed for a single image; empty or `nil` uses the file name.
    ///   - directory: overrides "next to the source" (used after a permission error).
    public static func makeJobs(
        sources: [URL], mode: BatchNameMode, singleName: String?, recipe: EditRecipe,
        settings: ExportSettings, namer: OutputFileNamer, directory: URL? = nil
    ) -> [ExportJob] {
        makeJobs(sources: sources, mode: mode, singleName: singleName,
                 recipes: Array(repeating: recipe, count: sources.count),
                 settings: settings, namer: namer, directory: directory)
    }

    /// Same as above with one recipe per source (each image in an editor batch has its own crop).
    public static func makeJobs(
        sources: [URL], mode: BatchNameMode, singleName: String?, recipes: [EditRecipe],
        settings: ExportSettings, namer: OutputFileNamer, directory: URL? = nil
    ) -> [ExportJob] {
        precondition(recipes.count == sources.count, "one recipe per source")
        let items = zip(sources, recipes).map { source, recipe -> OutputFileNamer.Item in
            let typed = sources.count == 1 ? singleName?.trimmingCharacters(in: .whitespaces) : nil
            return OutputFileNamer.Item(
                input: typed.flatMap { $0.isEmpty ? nil : $0 } ?? source.lastPathComponent,
                outputSize: outputSize(of: source, recipe: recipe),
                directory: directory ?? source.deletingLastPathComponent()
            )
        }
        let destinations = namer.plan(items, mode: mode, fileExtension: settings.format.fileExtension)
        return zip(zip(sources, recipes), destinations).map {
            ExportJob(source: $0.0, recipe: $0.1, settings: settings, destination: $1)
        }
    }

    /// Plans the failed jobs again for another folder, keeping each job's own recipe.
    public static func retarget(_ failed: [ExportJob], mode: BatchNameMode, singleName: String?,
                                namer: OutputFileNamer, directory: URL) -> [ExportJob] {
        guard let settings = failed.first?.settings else { return [] }
        return makeJobs(sources: failed.map(\.source), mode: mode, singleName: singleName, recipes: failed.map(\.recipe),
                        settings: settings, namer: namer, directory: directory)
    }

    /// Size the source will come out at, for the name suffix. An unreadable source gets the
    /// requested width; its export fails later with a clear error anyway.
    public static func outputSize(of source: URL, recipe: EditRecipe) -> PixelSize {
        guard let info = try? ImageSourceReader.readInfo(source) else {
            return PixelSize(width: recipe.resize.value ?? 1, height: 1)
        }
        let cropped = OutputGeometry.croppedSize(source: info.pixelSize, crop: recipe.crop)
        return OutputGeometry.outputSize(for: cropped, resize: recipe.resize).size
    }
}
