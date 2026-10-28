<div align="center">

<img src="docs/images/app-icon.png" width="128" alt="PixSEO icon">

# PixSEO

### One right-click: lighter images, the right size, SEO-ready file names

Resize, crop, watermark and rename images straight from the macOS Finder context menu.<br>
**Free · Works offline · No account · Open source**

[![Download](https://img.shields.io/github/v/release/khiemnguyendinh/pixseo?label=Download&style=for-the-badge&color=2f6bff)](https://github.com/khiemnguyendinh/pixseo/releases/latest)
![macOS 14+](https://img.shields.io/badge/macOS-14%2B-111?style=for-the-badge&logo=apple)
![Apple Silicon + Intel](https://img.shields.io/badge/Apple%20Silicon%20%2B%20Intel-universal-555?style=for-the-badge)
[![MIT](https://img.shields.io/badge/license-MIT-1ec773?style=for-the-badge)](LICENSE)

[Tiếng Việt](README.md) · **English** · [中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md)

<img src="docs/images/quick-resize-panel.jpg" width="640" alt="PixSEO Quick Resize panel: 1920 px, WebP, AI-suggested file name and alt text, estimated 6.8 MB down to 85 KB">

</div>

> **Note:** the app interface is currently in Vietnamese. It is built for Vietnamese content teams, but the workflow is the same in any language. Key labels are translated below.

---

## Why PixSEO?

Putting one photo on a website usually takes five steps. You open Photoshop or an online compressor, resize the image, export it, rename `IMG_4521.png` to something meaningful, and then hand-type an SEO-friendly slug.

PixSEO turns this into **right-click → pick a size → Enter**.

| Before | After PixSEO |
|---|---|
| `IMG_4521.png` · 3000×2000 · **6.8 MB** | `le-khai-giang-khoa-ai-marketing-k15-1920.webp` · 1920×1280 · **~85 KB** |
| Meaningless name, invisible to Google | Descriptive, keyword-rich name with the size |
| Heavy file slows the page | **99% smaller**, EXIF/GPS removed |
| Alt text written by hand | Alt text suggested and copied for you |

> Your original is **never touched**. The new file is saved next to it, PixSEO never overwrites anything, and there is an **Undo** button.

## Three actions, right in Finder

<img src="docs/images/finder-context-menu.png" width="640" alt="Finder context menu with Quick Resize (1080, 1440, 1600 px…), Quick Crop and Quick Watermark">

### ⚡ Quick Resize: done in two seconds
- Pick a width straight from the menu: **1080 · 1440 · 1600 · 1920 · 4K**, or type your own.
- Export **WebP, JPEG, PNG** or **GIF**; animated GIFs keep their animation.
- Set a **file-size cap** (≤ 100/200/300/500 KB) and PixSEO finds the right quality to meet it.
- Choose **72 / 96 PPI**.
- See the estimated size *before* saving, with a green/amber/red badge.
- Batch hundreds of images with numbered names: `shared-name-01-1920.webp`, `-02`…

### ✂️ Quick Crop: subject-aware cropping

<img src="docs/images/editor-smart-crop.jpg" width="760" alt="PixSEO Editor, Crop tab: 1:1 ratio placed around the main text, output 1920×1920">

- Free crop or common ratios: **1:1 · 4:5 · 3:4 · 2:3 · 3:2 · 4:3 · 16:9 · 9:16**.
- **OG 1200×630** for link previews on Facebook, LinkedIn and X.
- **Fit to subject**: the frame centers on faces and the main subject, so heads don't get cut off.
- Rotate and flip; nudge pixel by pixel with the arrow keys.
- Crop a whole batch; each image is fitted around its own subject.

### 🖋 Quick Watermark: brand every image

<img src="docs/images/editor-watermark.jpg" width="760" alt="PixSEO Editor, Watermark tab: '© Kstudy Academy' text in the bottom-right corner">

- Use a **text** or **logo** watermark (transparent PNG works best).
- Pick a font; fonts missing Vietnamese diacritics are flagged. Pick a color, including with an eyedropper.
- **Drag** to place it, and adjust size, opacity and rotation.
- **Auto corner** puts the mark in the emptiest corner of each image.
- Save **presets** and apply one right from Quick Resize to resize and brand in a single step.

### ✨ Smart SEO, entirely on your Mac
- **Automatic SEO slugs**: `Khai Giảng K15.png` → `khai-giang-k15-1920.webp` (lowercase, diacritics removed, hyphens, size suffix).
- **Reads text in the image** (OCR): a banner saying "KHAI GIẢNG K15" is suggested as `khai-giang-k15`.
- **Apple Intelligence** (macOS 26) suggests a title and **alt text**. Your images never leave your Mac.
- **Spots meaningless names** from cameras and chat apps (`IMG_`, `z5678…`, `received_…`).
- An **SEO ✓ badge** checks file size, dimensions, name, format, metadata and alt text.

## Install in one minute

1. Download **`PixSEO-x.y.z.dmg`** from [**Releases**](https://github.com/khiemnguyendinh/pixseo/releases/latest), open it, and drag **PixSEO** to **Applications**.
2. Open PixSEO. When macOS says it *cannot verify* the app, click **Done**.
3. Go to **System Settings › Privacy & Security**, scroll down, click **Open Anyway** next to PixSEO, then click **Open**. You only do this once.
4. If PixSEO says the right-click menu is off ("Menu chuột phải chưa bật"), click **Bật ngay** (Enable) and tick PixSEO under Finder.

> **Why step 3?** PixSEO is free and open source, and it isn't signed with a paid Apple Developer account, so macOS asks once. You can read the code or [build it yourself](#build-from-source).

## Keyboard shortcuts

| Where | Keys |
|---|---|
| Quick Resize panel | **⏎** Save · **Esc** Cancel · **⌘E** Open Editor |
| Editor | **⌘1/2/3** switch tab · **⌘← ⌘→** previous/next image · **⏎** Save · **⌥⏎** Save and keep the window open |
| Crop | Arrow keys: 1 px · **⇧** + arrows: 10 px |
| Watermark | **⌫** removes the watermark |

## Privacy

- No cloud, no account, no tracking. Everything, including the AI, runs on your Mac.
- EXIF data and GPS location are removed from exported images.
- PixSEO only reads the images you choose and only writes new files next to them.

## Build from source

Command Line Tools are enough; Xcode is not required.

```bash
xcode-select --install
scripts/test.sh        # run the 75 tests
scripts/install.sh     # build, install to /Applications, enable the Finder menu
scripts/make-dmg.sh    # create release/PixSEO-<version>.dmg (universal)
```

## Contributing

Bug reports and ideas are welcome in [Issues](https://github.com/khiemnguyendinh/pixseo/issues), and so are pull requests. If PixSEO saves you time, please give it a ⭐.

## License

[MIT](LICENSE). PixSEO bundles [libwebp](https://chromium.googlesource.com/webm/libwebp) (BSD); see [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES).
