# PixSEO

Chuột phải ảnh trong Finder → resize, crop, đóng watermark và lưu với tên chuẩn SEO. Miễn phí, chạy offline, cho macOS 14 trở lên.

*Right-click an image in Finder to resize, crop, watermark and save it with an SEO-friendly name. Free, offline, macOS 14+. [English below](#english).*

## Tính năng

- **Quick Resize**: chọn chiều rộng 1080 / 1440 / 1600 / 1920 / 4K ngay trong menu chuột phải. Xuất WebP, JPEG, PNG hoặc GIF (giữ ảnh động). Đặt được giới hạn dung lượng (≤ 100–500 KB) và PPI 72/96. Panel hiện trước dung lượng file mới.
- **Quick Crop**: crop tự do hoặc theo tỉ lệ 1:1, 4:5, 3:4, 2:3, 3:2, 4:3, 16:9, 9:16, OG 1200×630. Khung tự đặt quanh khuôn mặt hoặc chủ thể. Có xoay và lật. Crop nhiều ảnh một lần, mỗi ảnh căn theo chủ thể riêng.
- **Quick Watermark**: chèn chữ (chọn font, đánh dấu font thiếu dấu tiếng Việt, chọn màu, hút màu) hoặc logo. Kéo để đặt vị trí, chỉnh cỡ, độ mờ và góc xoay. Có chế độ tự chọn góc trống. Lưu được thành preset; chọn preset ngay trong panel Quick Resize.
- **Tên chuẩn SEO**: tên được chuyển thành chữ thường, bỏ dấu, nối bằng gạch ngang và thêm cỡ ảnh, ví dụ `Khai Giảng K15.png` → `khai-giang-k15-1920.webp`. Tên vẫn sửa được trước khi lưu.
- **Gợi ý thông minh**: đọc chữ trong ảnh (OCR tiếng Việt) để gợi ý tên. Trên macOS 26 có Apple Intelligence thì AI chạy ngay trên máy gợi ý thêm tên và alt text. Huy hiệu SEO kiểm tra dung lượng, kích thước, tên, định dạng và alt.
- **An toàn**: luôn giữ ảnh gốc và không ghi đè file nào. Xóa EXIF/GPS. Lưu xong có nút Hoàn tác.

## Cài đặt

1. Tải `PixSEO-x.y.z.dmg` ở trang [Releases](../../releases), mở ra rồi kéo PixSEO vào Applications.
2. Mở PixSEO. macOS báo không kiểm tra được ứng dụng: bấm **Xong**.
3. Vào **Cài đặt hệ thống › Quyền riêng tư & Bảo mật**, bấm **Vẫn mở** cạnh dòng PixSEO, rồi bấm **Mở**. Bước này chỉ làm một lần, vì PixSEO chưa được ký bằng tài khoản Apple Developer trả phí.
4. Nếu cửa sổ PixSEO báo *Menu chuột phải chưa bật*, bấm **Bật ngay** và tích PixSEO trong mục Finder.

Gỡ cài đặt: kéo PixSEO vào Thùng rác. Dữ liệu cài đặt nằm ở `~/Library/Application Support/PixSEO`.

## Phím tắt

| Ở đâu | Phím |
|---|---|
| Panel Quick Resize | ⏎ Lưu · Esc Hủy · ⌘E Mở Editor |
| Editor | ⌘1/2/3 đổi tab · ⌘← / ⌘→ đổi ảnh · ⏎ Lưu · ⌥⏎ Lưu và giữ cửa sổ · Esc Đóng |
| Crop | Mũi tên dịch khung 1 px, giữ ⇧ để dịch 10 px |
| Watermark | ⌫ gỡ watermark |

## Build từ mã nguồn

Chỉ cần Command Line Tools, không cần Xcode:

```bash
xcode-select --install
scripts/test.sh          # chạy test
scripts/install.sh       # build, cài vào /Applications, bật extension
scripts/make-dmg.sh      # tạo release/PixSEO-<version>.dmg (universal)
```

Xem thêm [docs/deployment-guide.md](docs/deployment-guide.md) và [docs/system-architecture.md](docs/system-architecture.md).

---

## English

PixSEO adds **Quick Resize**, **Quick Crop** and **Quick Watermark** to Finder's right-click menu for images.

- **Saving:** the original is never touched. A new file is saved next to it with an SEO name: lowercase, Vietnamese diacritics removed, hyphens, and a size suffix.
- **Output:** WebP, JPEG, PNG or GIF. You can set a byte limit, 72/96 PPI, and pick a crop ratio, including OG 1200×630. Crops snap to the subject of each image.
- **Watermarks:** text or a logo, saved as presets.
- **Suggestions:** OCR, plus on-device Apple Intelligence on macOS 26, suggests names and alt text.

**Install:** open the DMG and drag PixSEO to Applications. Open it once and click Done when macOS refuses. Then go to System Settings › Privacy & Security and click **Open Anyway**. The app is ad-hoc signed: it has no paid Apple Developer ID.

If the window says the right-click menu is off, click **Bật ngay** (Enable) and tick PixSEO under Finder.

**Build:** use the commands above. Command Line Tools are enough.

License: MIT ([LICENSE](LICENSE)). Bundles libwebp (BSD); see [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES).
