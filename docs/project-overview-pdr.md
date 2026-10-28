# PixSEO: tổng quan sản phẩm (PDR)

## Vấn đề
Người làm nội dung, marketing và web cần ảnh nhẹ, đúng cỡ, có tên chuẩn SEO. Hiện họ phải mở Photoshop hoặc dùng web tool, rồi tự đặt lại tên. PixSEO đưa các việc này vào menu chuột phải của Finder.

## Người dùng
Người làm nội dung và marketing tại Việt Nam (tên file có dấu, ảnh Zalo/Messenger), cộng đồng macOS nói chung.

## Yêu cầu chức năng
| Mã | Yêu cầu | Trạng thái |
|---|---|---|
| F1 | Quick Resize theo chiều rộng 1080/1440/1600/1920/4K + tự nhập; WebP/JPEG/PNG/GIF; PPI 72/96; giới hạn KB | Xong |
| F2 | Quick Crop tự do và theo tỉ lệ (1:1, 4:5, 3:4, 2:3, 3:2, 4:3, 16:9, 9:16, OG 1200×630); xoay, lật; căn theo chủ thể; batch | Xong |
| F3 | Quick Watermark: chữ (font, màu, hút màu) hoặc logo; kéo, cỡ, độ mờ, xoay; preset; tự chọn góc | Xong |
| F4 | Giữ ảnh gốc; lưu cùng thư mục, tên SEO (chữ thường, bỏ dấu, gạch ngang, hậu tố cỡ); sửa tên trước khi lưu | Xong |
| F5 | Gợi ý tên + alt text: OCR/nhãn (mọi máy), Apple Intelligence on-device (macOS 26) | Xong |
| F6 | Huy hiệu SEO: dung lượng, kích thước, tên, định dạng, metadata, alt | Xong |
| F7 | Home kéo thả, hướng dẫn lần đầu, Cài đặt 4 tab | Xong |
| F8 | Phát hành DMG universal trên GitHub, ký ad-hoc | Xong (chưa publish) |

## Phi chức năng
- Không cloud, không thu thập dữ liệu; xóa EXIF/GPS.
- Không bao giờ ghi đè (`renamex_np` + `RENAME_EXCL`); có Hoàn tác.
- Ảnh 24 MP → WebP 1920 < 1.2 s (bản release); app < 5 MB; tự thoát khi rảnh.
- Build bằng Command Line Tools, không cần Xcode.

## Ngoài phạm vi (backlog)
Cloud AI (Claude API, 07b), zoom canvas, ký Developer ID + notarize, độ dài tên tối đa tùy chỉnh.
