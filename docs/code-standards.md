# Chuẩn code

- Swift 6, strict concurrency. UI và model UI là `@MainActor`; xử lý ảnh chạy trong `Task.detached`.
- File Swift đặt tên PascalCase theo kiểu chính; mục tiêu < 200 dòng/file, tách bằng extension (`EditorViewModel+Preview`).
- Logic quyết định (tỉ lệ, đặt tên, cảnh báo, layout watermark, checklist SEO) nằm trong `PixSEOCore` và có test; view chỉ nối dữ liệu.
- Comment mô tả *vì sao*, không ghi mã plan/phase.
- Chuỗi giao diện tiếng Việt; lời khuyên và lỗi gom ở `UserFacingText`.
- Không ghi đè file người dùng; không bao giờ xóa ngoài thư mục của app (logo preset) hoặc qua Thùng rác (Hoàn tác).
- Test: swift-testing, chạy `scripts/test.sh` (thêm đường dẫn Testing.framework cho CLT). Ảnh test sinh bằng code (`FixtureFactory`), không có file nhị phân.
- Không dùng macro (`@Generable`, `#Preview`) vì CLT thiếu plugin macro.
