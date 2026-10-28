# Build, ký, phát hành

## Yêu cầu
macOS 14+, Command Line Tools (`xcode-select --install`). Không cần Xcode.

## Lệnh
| Việc | Lệnh |
|---|---|
| Test | `scripts/test.sh` (thêm `--filter TênTest`) |
| Build app | `scripts/build-app.sh release` → `build/PixSEO.app` |
| Cài máy mình | `scripts/install.sh` (copy vào /Applications, đăng ký và bật extension) |
| Universal DMG | `scripts/make-dmg.sh` → `release/PixSEO-<version>.dmg` + `.sha256` |
| Vẽ lại icon | `scripts/make-icon.sh` |

`PIXSEO_ARCHS="arm64 x86_64"` cho bản universal; `PIXSEO_SIGN_ID` chọn danh tính ký (mặc định `-` = ad-hoc).

## Ký
- Mặc định ký ad-hoc + hardened runtime (chưa có Apple Developer). Người tải phải bấm **Vẫn mở** trong Quyền riêng tư & Bảo mật một lần.
- Muốn quyền TCC không bị hỏi lại sau mỗi lần build trên máy mình: tạo chứng chỉ tự ký "PixSEO Local" trong Keychain Access (Certificate Assistant › Create a Certificate › Code Signing), rồi `PIXSEO_SIGN_ID="PixSEO Local" scripts/install.sh`.
- Khi có Developer ID: `PIXSEO_SIGN_ID="Developer ID Application: …" scripts/make-dmg.sh`, rồi `xcrun notarytool submit … --wait` và `xcrun stapler staple`.

## Phát hành
1. Tăng `CFBundleShortVersionString`/`CFBundleVersion` trong `Resources/App/Info.plist` (cả extension).
2. Gắn tag `vX.Y.Z` và push: GitHub Actions (`.github/workflows/build.yml`) chạy test, tạo DMG, mở **draft release**. Người bảo trì kiểm tra rồi bấm Publish.

## Gỡ cài đặt
Thoát PixSEO, xóa `/Applications/PixSEO.app`; tùy chọn xóa `~/Library/Application Support/PixSEO` và `defaults delete app.pixseo.mac`.
