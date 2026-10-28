<div align="center">

<img src="docs/images/app-icon.png" width="128" alt="PixSEO アイコン">

# PixSEO

### 右クリックひとつで、軽く・正しいサイズ・SEO に強いファイル名に

macOS の Finder の右クリックメニューから、画像のリサイズ、トリミング、透かし入れ、SEO 向けのリネームができます。<br>
**無料 · オフライン · アカウント不要 · オープンソース**

[![ダウンロード](https://img.shields.io/github/v/release/khiemnguyendinh/pixseo?label=%E3%83%80%E3%82%A6%E3%83%B3%E3%83%AD%E3%83%BC%E3%83%89&style=for-the-badge&color=2f6bff)](https://github.com/khiemnguyendinh/pixseo/releases/latest)
![macOS 14+](https://img.shields.io/badge/macOS-14%2B-111?style=for-the-badge&logo=apple)
![Apple Silicon + Intel](https://img.shields.io/badge/Apple%20Silicon%20%2B%20Intel-universal-555?style=for-the-badge)
[![MIT](https://img.shields.io/badge/license-MIT-1ec773?style=for-the-badge)](LICENSE)

[Tiếng Việt](README.md) · [English](README.en.md) · [中文](README.zh-CN.md) · **日本語** · [한국어](README.ko.md) · [Español](README.es.md)

<img src="docs/images/quick-resize-panel.jpg" width="640" alt="PixSEO の Quick Resize パネル：1920 px、WebP、AI が提案したファイル名と代替テキスト、6.8 MB から 85 KB へ">

</div>

> **注意：** 現在のアプリ画面はベトナム語です（ベトナムのコンテンツ制作者向け）。ただし操作の流れは言語に依存しません。主なボタンの意味は下に記載しています。

---

## PixSEO が必要な理由

Web に写真を 1 枚載せるだけで、たいてい次の 5 ステップがかかります。

1. Photoshop や圧縮サイトを開く
2. リサイズする
3. 書き出す
4. `IMG_4521.png` を意味のある名前に変える
5. SEO 向けの形式に手で直す

PixSEO なら **右クリック → サイズを選ぶ → Enter** だけです。

| これまで | PixSEO なら |
|---|---|
| `IMG_4521.png` · 3000×2000 · **6.8 MB** | `le-khai-giang-khoa-ai-marketing-k15-1920.webp` · 1920×1280 · **約 85 KB** |
| 意味のない名前で検索エンジンに伝わらない | 内容とキーワード、サイズを含む名前 |
| 重い画像でページが遅くなる | **99% 軽量化**、EXIF/GPS も削除 |
| 代替テキスト（alt）を手入力 | alt を自動提案し、保存後に自動コピー |

> 元画像は **一切変更しません**。新しいファイルは元画像の隣に保存され、上書きは一切ありません。**取り消し**もできます。

## Finder の中で 3 つの操作

<img src="docs/images/finder-context-menu.png" width="640" alt="Finder の右クリックメニュー：Quick Resize（1080、1440、1600 px…）、Quick Crop、Quick Watermark">

### ⚡ Quick Resize：2 秒でリサイズ
- メニューから横幅を選択：**1080 · 1440 · 1600 · 1920 · 4K**、または任意の値。
- 書き出し形式は **WebP、JPEG、PNG、GIF**。アニメーション GIF はアニメーションを保持します。
- **ファイルサイズ上限**（≤ 100/200/300/500 KB）を指定すると、最適な画質を自動で探します。
- **72 / 96 PPI** を選べます。
- 保存前に推定サイズを表示し、緑・黄・赤のバッジで知らせます。
- 数百枚の一括処理にも対応し、連番で名前を付けます。

### ✂️ Quick Crop：被写体を自動で捉えるトリミング

<img src="docs/images/editor-smart-crop.jpg" width="760" alt="PixSEO エディタのトリミング画面：1:1 の枠が主題の文字に合わせて配置され、1920×1920 で出力">

- 比率：自由、**1:1 · 4:5 · 3:4 · 2:3 · 3:2 · 4:3 · 16:9 · 9:16**、**OG 1200×630**（SNS 共有画像）。
- **被写体に合わせる**：顔や主要な被写体を中心に枠を自動配置するので、頭が切れません。
- 回転と反転ができ、矢印キーで 1 px ずつ調整できます。
- 一括トリミングでは、画像ごとにそれぞれの被写体へ合わせます。

### 🖋 Quick Watermark：すべての画像にブランドを

<img src="docs/images/editor-watermark.jpg" width="760" alt="PixSEO エディタの透かし画面：右下にテキスト透かし © Kstudy Academy">

- **テキスト**または**ロゴ**の透かし。フォントと色を選べます（スポイトあり）。
- **ドラッグ**で配置し、サイズ・不透明度・回転を調整できます。
- **空いている角を自動選択**するので、顔や文字に重なりません。
- **プリセット**として保存し、Quick Resize からリサイズと透かしを 1 回で適用できます。

### ✨ スマート SEO、すべて Mac 上で処理
- SEO 向けファイル名を自動生成します（小文字、ベトナム語の声調記号を除去、ハイフン区切り、サイズ付き）。
- 画像内の文字を **OCR** で読み取り、名前を提案します。
- **Apple Intelligence**（macOS 26）がタイトルと **alt テキスト** を提案します。画像は Mac の外に出ません。
- **SEO ✓ バッジ** で次の項目をチェックします：
  - サイズ
  - 寸法
  - 名前
  - 形式
  - メタデータ
  - alt

## 1 分でインストール

1. [**Releases**](https://github.com/khiemnguyendinh/pixseo/releases/latest) から **`PixSEO-x.y.z.dmg`** をダウンロードし、**PixSEO** を **アプリケーション** にドラッグします。
2. PixSEO を開きます。「検証できません」と表示されたら **完了** をクリックします。
3. **システム設定 › プライバシーとセキュリティ** を開き、PixSEO の横の **このまま開く** をクリックしてから **開く** をクリックします（最初の 1 回だけ）。
4. 右クリックメニューが無効（「Menu chuột phải chưa bật」）と表示されたら、**Bật ngay**（有効にする）をクリックし、Finder の項目で PixSEO にチェックを入れます。

> **なぜ手順 3 が必要？** PixSEO は無料のオープンソースで、有料の Apple Developer アカウントで署名していないため、macOS が一度だけ確認を求めます。

## プライバシー
- クラウドもアカウントもトラッキングもありません。AI を含むすべての処理が Mac 上で完結します。
- 書き出した画像からは EXIF と GPS 位置情報が削除されます。

## ソースからビルド

```bash
xcode-select --install
scripts/test.sh
scripts/install.sh
scripts/make-dmg.sh
```

## ライセンス

[MIT](LICENSE)。[libwebp](https://chromium.googlesource.com/webm/libwebp)（BSD）を同梱しています。詳しくは [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES) をご覧ください。役に立ったら ⭐ をお願いします。
