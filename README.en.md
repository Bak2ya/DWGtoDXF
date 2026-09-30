<p align="center">
  <img src="src/DWG2DXF.Web/wwwroot/assets/app_logo.png" width="96" alt="DWG2DXF icon">
</p>

<h1 align="center">DWG2DXF</h1>

<p align="center">
  A simple tool for converting DWG files to DXF for use with LibreCAD
</p>

<p align="center">
  <a href="https://bak2ya.github.io/DWGtoDXF/">Open Web App</a>
  ·
  <a href="https://github.com/Bak2ya/DWGtoDXF/releases">Windows App</a>
  ·
  <a href="README.md">한국어 README</a>
</p>

## Use it now

### 🌐 Web app
[**Open DWG2DXF Web**](https://bak2ya.github.io/DWGtoDXF/)

No installation is required. DWG files are processed locally inside the browser and are not uploaded to a conversion server.

### 🪟 Windows app
[**Download the Windows version**](https://github.com/Bak2ya/DWGtoDXF/releases)

The Windows desktop build is distributed through GitHub Releases.

## Supported interface languages

- 한국어
- English
- 日本語
- Español

The web app detects the browser language on first launch. The **Language** control is always visible in the header, and your manual selection is saved in the browser.

The interface language does **not** control font conversion. A drawing may contain Korean, Japanese, Chinese, or other text regardless of the language used for the UI.

## Main features

- DWG → DXF conversion in the browser
- macOS / Windows / Linux browser support
- Multiple DWG files
- DWG header validation
- AutoCAD 2010 DXF output or original DWG version
- Three font modes:
  - Do not convert
  - Replace all text with `wqy-unicode`
  - Replace CJK text only
- Language-specific default recommendation:
  - Korean / Japanese UI → **Replace all text**
  - English / Spanish UI → **Do not convert**
- Korean, Japanese, and common CJK character detection
- Re-read the generated DXF and compare major object counts
- Progress stages and activity animation during long conversions
- Individual DXF downloads
- Download all converted files as ZIP
- Dark mode
- LibreCAD `wqy-unicode.lff` download and installation guide
- Original DWG files are never modified

## CJK font compatibility

Some DWG drawings contain text styles that LibreCAD cannot render correctly.

DWG2DXF can point text styles to `wqy-unicode.lff`. The CJK-only mode detects common:

- Hangul
- Hiragana
- Katakana
- CJK Unified Ideographs / common Han characters

CJK means **Chinese, Japanese, and Korean** characters. This explanation is always visible next to the font options.

For maximum compatibility when CJK text is actually garbled, **Replace all text** remains the most reliable mode. If text already displays correctly, no font conversion is necessary.

## What “Review” means

After conversion, DWG2DXF re-opens the generated DXF and compares major object counts.

If a difference is detected, the conversion result is marked **Review**. This does not automatically mean the drawing is damaged. It means the result should be visually checked in LibreCAD.

Proxy, AEC, Civil, XREF-related, and other special CAD objects are not guaranteed to convert perfectly.

## LibreCAD font installation

Open **More → LibreCAD font guide** in the web app.

1. Download `wqy-unicode.lff`.
2. In LibreCAD, check **Application Preferences → Paths → Fonts**.
3. Copy the font file to that folder.
4. Fully quit LibreCAD.
5. Start LibreCAD again.

## Technology

- .NET 8
- Blazor WebAssembly
- ACadSharp 3.6.51
- GitHub Pages

Conversion runs inside the browser using WebAssembly.

## Source code

The source code is included in this repository:

**https://github.com/Bak2ya/DWGtoDXF**

No separate license for the DWG2DXF project itself has been added at this time. Third-party license notices remain included in the repository.

## Local development

.NET 8 SDK is required.

```bash
dotnet restore src/DWG2DXF.Web/DWG2DXF.Web.csproj
dotnet run --project src/DWG2DXF.Web/DWG2DXF.Web.csproj
```

## GitHub Pages deployment

Pushing to the `main` branch triggers the included GitHub Actions workflow.

Web app:

**https://bak2ya.github.io/DWGtoDXF/**

## Third-party components

- ACadSharp 3.6.51 — MIT License
- `wqy-unicode.lff` — Apache License 2.0 or GPLv3  
  This repository redistributes the font under the Apache License 2.0 terms.

See `THIRD_PARTY_NOTICES.txt` and the license files under `wwwroot/assets/licenses/`.
