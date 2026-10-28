<div align="center">

<img src="docs/images/app-icon.png" width="128" alt="PixSEO 아이콘">

# PixSEO

### 우클릭 한 번이면 끝: 가벼운 용량, 알맞은 크기, SEO에 맞는 파일 이름

macOS Finder 우클릭 메뉴에서 바로 이미지 크기 조절, 자르기, 워터마크, SEO 파일 이름 변경까지 끝냅니다.<br>
**무료 · 오프라인 · 계정 불필요 · 오픈 소스**

[![다운로드](https://img.shields.io/github/v/release/khiemnguyendinh/pixseo?label=%EB%8B%A4%EC%9A%B4%EB%A1%9C%EB%93%9C&style=for-the-badge&color=2f6bff)](https://github.com/khiemnguyendinh/pixseo/releases/latest)
![macOS 14+](https://img.shields.io/badge/macOS-14%2B-111?style=for-the-badge&logo=apple)
![Apple Silicon + Intel](https://img.shields.io/badge/Apple%20Silicon%20%2B%20Intel-universal-555?style=for-the-badge)
[![MIT](https://img.shields.io/badge/license-MIT-1ec773?style=for-the-badge)](LICENSE)

[Tiếng Việt](README.md) · [English](README.en.md) · [中文](README.zh-CN.md) · [日本語](README.ja.md) · **한국어** · [Español](README.es.md)

<img src="docs/images/quick-resize-panel.jpg" width="640" alt="PixSEO Quick Resize 패널: 1920 px, WebP, AI가 제안한 파일 이름과 대체 텍스트, 6.8 MB에서 85 KB로">

</div>

> **참고:** 현재 앱 화면은 베트남어입니다(베트남 콘텐츠 팀을 위해 제작). 사용 흐름은 언어와 상관없이 같으며, 주요 버튼 뜻은 아래에 적어 두었습니다.

---

## 왜 PixSEO인가요?

웹사이트에 사진 한 장을 올리려면 보통 다섯 단계를 거칩니다.

1. Photoshop이나 압축 사이트를 엽니다.
2. 크기를 조절합니다.
3. 내보냅니다.
4. `IMG_4521.png`를 의미 있는 이름으로 바꿉니다.
5. 그 이름을 SEO 형식에 맞게 다시 손봅니다.

PixSEO에서는 **우클릭 → 크기 선택 → Enter** 세 동작이면 됩니다.

| 이전 | PixSEO 사용 후 |
|---|---|
| `IMG_4521.png` · 3000×2000 · **6.8 MB** | `le-khai-giang-khoa-ai-marketing-k15-1920.webp` · 1920×1280 · **약 85 KB** |
| 의미 없는 이름이라 검색 엔진이 내용을 모름 | 내용과 키워드, 크기가 담긴 이름 |
| 무거운 이미지가 페이지를 느리게 함 | 용량 **99% 감소**, EXIF/GPS 삭제 |
| 대체 텍스트(alt)를 직접 작성 | alt를 자동으로 제안하고 저장 후 자동 복사 |

> 원본은 **절대 건드리지 않습니다**. 새 파일은 원본 옆에 저장되고 어떤 파일도 덮어쓰지 않으며, **실행 취소**도 됩니다.

## Finder 안에서 끝나는 세 가지 작업

<img src="docs/images/finder-context-menu.png" width="640" alt="Finder 우클릭 메뉴: Quick Resize(1080, 1440, 1600 px…), Quick Crop, Quick Watermark">

### ⚡ Quick Resize: 2초 만에 크기 조절
- 메뉴에서 바로 너비를 고릅니다: **1080 · 1440 · 1600 · 1920 · 4K** 또는 직접 입력.
- **WebP, JPEG, PNG, GIF**로 내보내며, 움직이는 GIF는 애니메이션을 유지합니다.
- **용량 상한**(≤ 100/200/300/500 KB)을 정하면 그 안에 맞는 화질을 자동으로 찾습니다.
- **72 / 96 PPI**를 선택할 수 있습니다.
- 저장하기 전에 예상 용량을 보여 주고, 초록·노랑·빨강 배지로 표시합니다.
- 수백 장을 한 번에 처리하고 번호를 붙여 이름을 짓습니다.

### ✂️ Quick Crop: 피사체를 알아보는 자르기

<img src="docs/images/editor-smart-crop.jpg" width="760" alt="PixSEO 편집기 자르기 탭: 1:1 프레임이 주요 문구에 맞춰 배치되고 1920×1920으로 출력">

- 자유 비율 또는 **1:1 · 4:5 · 3:4 · 2:3 · 3:2 · 4:3 · 16:9 · 9:16**, SNS 공유용 **OG 1200×630**을 지원합니다.
- **피사체에 맞추기**: 얼굴과 주요 피사체를 중심으로 프레임을 잡아 머리가 잘리지 않습니다.
- 회전과 뒤집기가 되고, 화살표 키로 1 px씩 조정합니다.
- 여러 장을 한 번에 자르면 사진마다 각자의 피사체에 맞춥니다.

### 🖋 Quick Watermark: 모든 이미지에 브랜드를

<img src="docs/images/editor-watermark.jpg" width="760" alt="PixSEO 편집기 워터마크 탭: 오른쪽 아래 텍스트 워터마크 © Kstudy Academy">

- **텍스트** 또는 **로고** 워터마크를 넣습니다. 글꼴과 색상을 고를 수 있고 스포이트도 있습니다.
- **드래그**로 위치를 잡고 크기, 불투명도, 회전을 조절합니다.
- **빈 모서리 자동 선택**으로 얼굴이나 글자를 가리지 않습니다.
- **프리셋**으로 저장해 두면 Quick Resize에서 크기 조절과 워터마크를 한 번에 처리합니다.

### ✨ 스마트 SEO, 모두 Mac 안에서
- SEO용 파일 이름을 자동으로 만듭니다. 소문자로 바꾸고, 베트남어 성조 기호를 없애고, 하이픈으로 잇고, 크기를 붙입니다.
- 이미지 속 글자를 **OCR**로 읽어 이름을 제안합니다.
- **Apple Intelligence**(macOS 26)가 제목과 **alt 텍스트**를 제안합니다. 이미지는 Mac 밖으로 나가지 않습니다.
- **SEO ✓ 배지**로 다음 항목을 점검합니다:
  - 용량
  - 크기
  - 이름
  - 형식
  - 메타데이터
  - alt

## 1분 설치

1. [**Releases**](https://github.com/khiemnguyendinh/pixseo/releases/latest)에서 **`PixSEO-x.y.z.dmg`**를 내려받아 **PixSEO**를 **응용 프로그램** 폴더로 끌어다 놓습니다.
2. PixSEO를 엽니다. '확인할 수 없음' 경고가 뜨면 **완료**를 누릅니다.
3. **시스템 설정 › 개인정보 보호 및 보안**에서 PixSEO 옆의 **그래도 열기**를 누른 뒤 **열기**를 누릅니다. 이 과정은 처음 한 번만 합니다.
4. 우클릭 메뉴가 꺼져 있다는 메시지("Menu chuột phải chưa bật")가 보이면 **Bật ngay**(켜기)를 누르고 Finder 항목에서 PixSEO를 체크합니다.

> **왜 3단계가 필요한가요?** PixSEO는 무료 오픈 소스이고 유료 Apple 개발자 계정으로 서명하지 않았기 때문에, macOS가 한 번 확인을 요청합니다.

## 개인정보 보호
- 클라우드, 계정, 추적이 없습니다. AI를 포함한 모든 처리가 Mac 안에서 이뤄집니다.
- 내보낸 이미지에서는 EXIF와 GPS 위치 정보를 삭제합니다.

## 소스에서 빌드

```bash
xcode-select --install
scripts/test.sh
scripts/install.sh
scripts/make-dmg.sh
```

## 라이선스

[MIT](LICENSE). [libwebp](https://chromium.googlesource.com/webm/libwebp)(BSD)를 포함하며, 자세한 내용은 [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES)에 있습니다. 도움이 되셨다면 ⭐를 눌러 주세요.
