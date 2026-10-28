# Kiến trúc hệ thống

```
Finder ──chuột phải──▶ PixSEOFinder.appex (FinderSync, sandbox)
                         │  pixseo://run?a=resize&w=1920&f=… (chia 50 file/URL)
                         ▼
PixSEO.app (LSUIElement, AppKit + SwiftUI)
  AppDelegate ─ kAEGetURL ─▶ SenderVerifier (PID người gửi ∈ PlugIns/ → trusted)
       │                      IntakeRouter (ghép batch, kiểm ảnh bằng ImageIO, tối đa 500)
       ▼
  QuickSaveCoordinator ── resize/open ──▶ QuickSavePanel (NSPanel nổi)
       │              └─ crop/watermark ─▶ EditorCoordinator ─▶ EditorWindow (Resize|Crop|Watermark)
       ▼
  ExportRunner ──▶ ExportService (PixSEOCore) ──▶ Toast (Hiện trong Finder / Hoàn tác)
  HomeWindow (kéo thả, onboarding) · SettingsWindow (4 tab) · MainMenu (⌘C/⌘V/⌘,)
```

## Module
| Target | Vai trò | Phụ thuộc |
|---|---|---|
| `PixSEOShared` | Mã hóa request URL, loại file hỗ trợ, cỡ preset. An toàn cho extension. | — |
| `PixSEOCore` | Engine ảnh, encoder, đặt tên SEO, hình học crop, watermark, Vision, AI, SEO checklist. Không UI, test được. | Shared, libwebp |
| `PixSEOApp` | UI và điều phối. | Shared, Core |
| `PixSEOFinderExt` | Menu Finder; build bằng `swiftc` trong `build-app.sh`. | Shared (biên dịch chung nguồn) |

## Đường ống xuất (ExportService.render)
`ImageSourceReader` (giải mã theo orientation, downsample 2× nhu cầu) → `RenderPipeline` (xoay/lật → crop → Lanczos → unsharp nhẹ → nền trắng cho JPEG → sRGB RGBA8 → `WatermarkRenderer`) → encoder (`WebPEncoder` libwebp / `ImageIOEncoder`) trong `TargetSizeOptimizer` (tìm nhị phân quality theo giới hạn KB) → `SafeFileWriter`.

Ảnh động GIF: render từng frame. Metadata luôn bị bỏ.

## Editor
`EditorViewModel` giữ crop riêng từng ảnh (`ImageEdit`), tỉ lệ chung, watermark chung. Canvas dùng preview ≤ 2048 px; bản xem cuối (crop + watermark) ≤ 1400 px, render bằng cùng `RenderPipeline` nên thấy gì xuất nấy. Ảnh chưa mở trong batch được tự căn chủ thể lúc lưu (`autoCrop`).

## AI và gợi ý
`ContentAnalyzer` (Vision: OCR vi/en có customWords, phân loại, khuôn mặt) → `HeuristicNameSuggester` (dòng chữ lớn nhất / nhãn dịch Việt) và `OnDeviceNameSuggester` (Foundation Models, `DynamicGenerationSchema`, timeout 20 s, macOS 26). Slug luôn do `SEOSlugger` tạo từ title. `SuggestionModel` cache theo đường dẫn + ngày sửa + dung lượng. Gợi ý không bao giờ sửa ô tên đang gõ: khi ô trống, tên gợi ý được dùng như giá trị ngầm.

## Lưu trữ
- `UserDefaults` key `exportPreferences` (JSON, thiếu key giữ mặc định).
- `~/Library/Application Support/PixSEO/watermark-presets.json` + `Logos/` (bản sao logo).
