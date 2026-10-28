# Tóm tắt codebase

| Thư mục | Nội dung |
|---|---|
| `Sources/PixSEOShared` | `IntakeRequest` (URL pixseo://), `IntakeBatchAssembler`, `SupportedImageTypes`, `SizePresets` |
| `Sources/PixSEOFinderExt` | `PixSEOFinderSync`: menu Quick Resize ▸ cỡ / Quick Crop… / Quick Watermark… |
| `Sources/PixSEOCore/Model` | `EditRecipe` (crop, resize, sharpen, watermark), `ExportSettings`, `OutputFormat`, `PixelSize`, lỗi/cảnh báo |
| `Sources/PixSEOCore/Engine` | `ExportService`, `RenderPipeline`, `ImageSourceReader`, `OutputGeometry`, `TargetSizeOptimizer`, `SafeFileWriter` |
| `Sources/PixSEOCore/Encoders` | `WebPEncoder` (libwebp), `ImageIOEncoder` (JPEG/PNG/GIF động) |
| `Sources/PixSEOCore/Naming` | `SEOSlugger`, `OutputFileNamer`, `MeaninglessNameDetector` |
| `Sources/PixSEOCore/Advice` | `ExportAdvisor`, `ExportPlanner` |
| `Sources/PixSEOCore/Geometry` | `AspectRatioPreset`, `CropMath`, `CanvasMapping` |
| `Sources/PixSEOCore/Watermark` | `WatermarkSpec` + `WatermarkLayout`, `WatermarkRenderer`, `WatermarkPresetStore`, `FontCoverage` |
| `Sources/PixSEOCore/Smart` | `SaliencyAnalyzer` + `SmartCropPlacement`, `WatermarkPlacementAdvisor`, `ContentAnalyzer` |
| `Sources/PixSEOCore/AI`, `SEO` | `NameSuggestion`, `HeuristicNameSuggester`, `OnDeviceNameSuggester`, `VietnameseLabelDictionary`, `SEOChecklist` |
| `Sources/PixSEOApp` | `AppDelegate`, `IntakeRouter`, `SenderVerifier`; `QuickSave/`, `Editor/`, `Crop/`, `Watermark/`, `Components/` (ExportOptions, FileNaming, SizeEstimator, SuggestionModel, NameSection…), `Home/`, `Settings/`, `Toast/`, `Support/` |
| `Tests/` | 75 test: request, đặt tên, hình học, engine, advisor, crop, watermark, AI heuristic, checklist |
| `scripts/` | `build-app.sh`, `install.sh`, `test.sh`, `make-dmg.sh`, `make-icon.sh` + `IconRenderer.swift` |
| `Resources/` | Info.plist app + extension, entitlements, `AppIcon.icns`, hướng dẫn trong DMG |
