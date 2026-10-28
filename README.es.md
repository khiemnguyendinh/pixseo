<div align="center">

<img src="docs/images/app-icon.png" width="128" alt="Icono de PixSEO">

# PixSEO

### Un clic derecho: imágenes más ligeras, al tamaño justo y con nombres SEO

Redimensiona, recorta, añade marcas de agua y renombra imágenes desde el menú contextual del Finder de macOS.<br>
**Gratis · Sin conexión · Sin cuentas · Código abierto**

[![Descargar](https://img.shields.io/github/v/release/khiemnguyendinh/pixseo?label=Descargar&style=for-the-badge&color=2f6bff)](https://github.com/khiemnguyendinh/pixseo/releases/latest)
![macOS 14+](https://img.shields.io/badge/macOS-14%2B-111?style=for-the-badge&logo=apple)
![Apple Silicon + Intel](https://img.shields.io/badge/Apple%20Silicon%20%2B%20Intel-universal-555?style=for-the-badge)
[![MIT](https://img.shields.io/badge/license-MIT-1ec773?style=for-the-badge)](LICENSE)

[Tiếng Việt](README.md) · [English](README.en.md) · [中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · **Español**

<img src="docs/images/quick-resize-panel.jpg" width="640" alt="Panel Quick Resize de PixSEO: 1920 px, WebP, nombre de archivo y texto alternativo sugeridos por IA, de 6,8 MB a 85 KB">

</div>

> **Nota:** por ahora la interfaz está en vietnamita, porque la app nació para equipos de contenido de Vietnam. El flujo de trabajo es el mismo en cualquier idioma; abajo traducimos los botones clave.

---

## ¿Por qué PixSEO?

Publicar una foto en una web suele llevar cinco pasos:

1. Abrir Photoshop o un compresor online.
2. Redimensionar la imagen.
3. Exportarla.
4. Cambiar `IMG_4521.png` por un nombre con sentido.
5. Escribir a mano un slug apto para SEO.

Con PixSEO basta con **clic derecho → elegir tamaño → Enter**.

| Antes | Con PixSEO |
|---|---|
| `IMG_4521.png` · 3000×2000 · **6,8 MB** | `le-khai-giang-khoa-ai-marketing-k15-1920.webp` · 1920×1280 · **~85 KB** |
| Nombre sin sentido para Google | Nombre descriptivo, con palabras clave y tamaño |
| Imagen pesada que ralentiza la página | **99 % más ligera**, sin EXIF ni GPS |
| Texto alternativo escrito a mano | Texto alternativo sugerido y copiado al guardar |

> El original **nunca se toca**. El archivo nuevo se guarda a su lado, PixSEO nunca sobrescribe nada y además puedes **Deshacer**.

## Tres acciones, dentro del Finder

<img src="docs/images/finder-context-menu.png" width="640" alt="Menú contextual del Finder con Quick Resize (1080, 1440, 1600 px…), Quick Crop y Quick Watermark">

### ⚡ Quick Resize: listo en dos segundos
- Elige el ancho desde el menú: **1080 · 1440 · 1600 · 1920 · 4K**, o escribe uno propio.
- Exporta a **WebP, JPEG, PNG** o **GIF**; los GIF animados conservan la animación.
- Fija un **límite de peso** (≤ 100/200/300/500 KB) y PixSEO busca la calidad justa para cumplirlo.
- Elige **72 / 96 PPI**.
- Ve el tamaño estimado antes de guardar, con una insignia verde, ámbar o roja.
- Procesa cientos de imágenes de una vez, con nombres numerados.

### ✂️ Quick Crop: recorte que entiende el sujeto

<img src="docs/images/editor-smart-crop.jpg" width="760" alt="Editor de PixSEO, pestaña Recortar: proporción 1:1 centrada en el texto principal, salida 1920×1920">

- Recorte libre o en proporciones habituales: **1:1 · 4:5 · 3:4 · 2:3 · 3:2 · 4:3 · 16:9 · 9:16**.
- **OG 1200×630** para las vistas previas de enlaces en redes sociales.
- **Ajustar al sujeto**: el marco se centra en caras y en el sujeto principal, sin cortar cabezas.
- Gira, voltea y ajusta píxel a píxel con las flechas.
- En lotes, cada imagen se ajusta a su propio sujeto.

### 🖋 Quick Watermark: tu marca en cada imagen

<img src="docs/images/editor-watermark.jpg" width="760" alt="Editor de PixSEO, pestaña Marca de agua: texto © Kstudy Academy en la esquina inferior derecha">

- Marca de agua de **texto** o de **logo**.
- Elige la fuente y el color; incluye cuentagotas.
- **Arrastra** para colocarla y ajusta tamaño, opacidad y rotación.
- **Esquina automática**: se coloca en la zona más despejada de cada imagen.
- Guárdala como **preajuste** y aplícala desde Quick Resize para redimensionar y marcar en un solo paso.

### ✨ SEO inteligente, todo en tu Mac
- Nombres SEO automáticos: minúsculas, sin diacríticos vietnamitas, con guiones y el tamaño al final.
- **OCR**: lee el texto de la imagen para sugerir el nombre.
- **Apple Intelligence** (macOS 26) sugiere título y **texto alternativo**. Tus imágenes no salen de tu Mac.
- Insignia **SEO ✓**: revisa el peso, las dimensiones, el nombre, el formato, los metadatos y el texto alternativo.

## Instalación en un minuto

1. Descarga **`PixSEO-x.y.z.dmg`** desde [**Releases**](https://github.com/khiemnguyendinh/pixseo/releases/latest) y arrastra **PixSEO** a **Aplicaciones**.
2. Abre PixSEO. Cuando macOS diga que no puede verificarla, pulsa **OK**.
3. Ve a **Ajustes del Sistema › Privacidad y seguridad**, pulsa **Abrir igualmente** junto a PixSEO y luego **Abrir**. Solo hace falta la primera vez.
4. Si la app avisa de que el menú contextual está desactivado ("Menu chuột phải chưa bật"), pulsa **Bật ngay** (Activar) y marca PixSEO en el apartado Finder.

> **¿Por qué el paso 3?** PixSEO es gratis y de código abierto. No está firmado con una cuenta de pago de Apple Developer, así que macOS pide confirmación una vez.

## Privacidad
- Sin nube, sin cuentas y sin rastreo: todo, incluida la IA, se ejecuta en tu Mac.
- Las imágenes exportadas no llevan datos EXIF ni ubicación GPS.

## Compilar desde el código

```bash
xcode-select --install
scripts/test.sh
scripts/install.sh
scripts/make-dmg.sh
```

## Licencia

[MIT](LICENSE). Incluye [libwebp](https://chromium.googlesource.com/webm/libwebp) (BSD); consulta [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES). Si PixSEO te ahorra tiempo, regálale una ⭐.
