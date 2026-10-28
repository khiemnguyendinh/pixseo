import Testing
@testable import PixSEOCore

struct ExportAdvisorTests {
    @Test func badgeThresholds() {
        #expect(ExportAdvisor.sizeBadge(bytes: 200 * 1024) == .good)
        #expect(ExportAdvisor.sizeBadge(bytes: 200 * 1024 + 1) == .fair)
        #expect(ExportAdvisor.sizeBadge(bytes: 500 * 1024 + 1) == .heavy)
    }

    @Test func formatAdviceFollowsContent() throws {
        let dir = try FixtureFactory.makeDirectory()
        let photoURL = try FixtureFactory.write([FixtureFactory.photo(width: 400, height: 300)], to: dir.appendingPathComponent("p.jpg"), type: .jpeg)
        let photo = try ImageSourceReader.readInfo(photoURL)
        #expect(ExportAdvisor.advice(info: photo, format: .png, width: 1920, estimateWarnings: []) == [.pngForPhoto])
        #expect(ExportAdvisor.advice(info: photo, format: .gif, width: 1920, estimateWarnings: []) == [.gifForStill])
        #expect(ExportAdvisor.advice(info: photo, format: .webp, width: 3840, estimateWarnings: []) == [.fourKForWeb])

        let logoURL = try FixtureFactory.write([FixtureFactory.photo(width: 400, height: 300, alpha: true)], to: dir.appendingPathComponent("l.png"), type: .png)
        let logo = try ImageSourceReader.readInfo(logoURL)
        #expect(ExportAdvisor.advice(info: logo, format: .jpeg, width: 1080, estimateWarnings: []) == [.transparencyWillBeWhite])
        #expect(ExportAdvisor.advice(info: logo, format: .png, width: 1080, estimateWarnings: []).isEmpty)
    }

    @Test func estimateWarningsBecomeAdvice() {
        let advice = ExportAdvisor.advice(info: nil, format: .webp, width: 1920, estimateWarnings: [
            .ppiIgnored, .notUpscaled(original: PixelSize(width: 800, height: 600)), .largerThanSource(percent: 12),
        ])
        #expect(advice == [.notUpscaled(original: PixelSize(width: 800, height: 600)), .largerThanSource(percent: 12)])
    }

    @Test func batchNamingDefaults() {
        #expect(ExportAdvisor.defaultBatchMode(for: ["IMG_1.jpg"]) == .individual)
        #expect(ExportAdvisor.defaultBatchMode(for: ["khai-giang.jpg", "tot-nghiep.jpg"]) == .individual)
        #expect(ExportAdvisor.defaultBatchMode(for: ["IMG_1.jpg", "IMG_2.jpg"]) == .shared(""))
        #expect(ExportAdvisor.defaultBatchMode(for: ["Lễ khai giảng 1.jpg", "le-khai-giang-2.jpg", "IMG_3.jpg"]) == .shared(""))
        #expect(ExportAdvisor.commonMeaningfulPrefix(["Lễ khai giảng 1.jpg", "le-khai-giang-2.jpg"]) == "le-khai-giang")
        #expect(ExportAdvisor.commonMeaningfulPrefix(["IMG_1.jpg", "IMG_2.jpg"]) == "")
    }
}

struct ExportPlannerTests {
    @Test func plansNamesNextToEachSource() throws {
        let dir = try FixtureFactory.makeDirectory()
        let a = try FixtureFactory.write([FixtureFactory.photo(width: 3000, height: 2000)], to: dir.appendingPathComponent("Khai Giảng K15.png"), type: .png)
        let b = try FixtureFactory.write([FixtureFactory.photo(width: 800, height: 600)], to: dir.appendingPathComponent("IMG_2.png"), type: .png)
        let recipe = EditRecipe(resize: ResizeSpec(value: 1920))
        let settings = ExportSettings()

        let single = ExportPlanner.makeJobs(sources: [a], mode: .individual, singleName: "  ", recipe: recipe, settings: settings, namer: OutputFileNamer())
        #expect(single.map(\.destination.lastPathComponent) == ["khai-giang-k15-1920.webp"])
        let typed = ExportPlanner.makeJobs(sources: [a], mode: .individual, singleName: "Lễ khai giảng", recipe: recipe, settings: settings, namer: OutputFileNamer())
        #expect(typed.first?.destination.lastPathComponent == "le-khai-giang-1920.webp")

        // The small image isn't enlarged, so its suffix is its real width.
        let batch = ExportPlanner.makeJobs(sources: [a, b], mode: .shared("su kien"), singleName: nil, recipe: recipe, settings: settings, namer: OutputFileNamer())
        #expect(batch.map(\.destination.lastPathComponent) == ["su-kien-01-1920.webp", "su-kien-02-800.webp"])
        #expect(batch.allSatisfy { $0.destination.deletingLastPathComponent().path == dir.path })
    }
}
