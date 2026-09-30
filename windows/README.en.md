# DWG2DXF Windows v1.3

Windows source/build kit for the DWG → DXF converter.

## v1.3

- Korean / English / Japanese / Spanish interface
- **Automatic Windows display-language detection on first launch**
  - Korean Windows → 한국어
  - Japanese Windows → 日本語
  - Spanish Windows → Español
  - Other languages → English
- Manual language selection from `Options → Language` is saved and takes priority on later launches
- The former Korean-only font mode is expanded to **CJK text only**
- A visible explanation states that CJK means Chinese, Japanese, and Korean characters
- Hangul, Hiragana, Katakana, and common Han/CJK character ranges are detected
- UI language and drawing text language remain independent

## Default font recommendation by UI language

Font conversion is intended for drawings where CJK text is garbled in LibreCAD.

- **Korean / Japanese UI**
  - Default: `All text (Recommended)`
- **English / Spanish UI**
  - Default: `Keep original (Recommended)`

All three font modes remain available in every UI language:

1. Keep original
2. All text
3. CJK text only

CJK-only mode attempts to preserve Latin/numeric styles while changing text that contains Chinese, Japanese, or Korean characters.

## Existing behavior retained

- Original DWG protection
- No silent DXF overwrite
- AutoCAD 2010 DXF recommended output
- DXF re-read validation
- Dark mode
- Output folder selection
- Bundled LibreCAD `wqy-unicode.lff` helper
- Stage-based progress updates
- Language-neutral `_converted` output suffixes

## Build

On Windows 10/11:

1. Extract the ZIP.
2. Double-click `BUILD_v1.3.cmd`.
3. Use `dist\DWG2DXF_v1.3.exe`.

Requirements: .NET Framework 4.8+, Windows PowerShell 5.1, and internet access for the first build. Administrator rights are not required.

The final EXE embeds ACadSharp, compatibility DLLs, `wqy-unicode.lff`, icons, and third-party notices.

Web app: https://bak2ya.github.io/DWGtoDXF/

Repository: https://github.com/Bak2ya/DWGtoDXF
