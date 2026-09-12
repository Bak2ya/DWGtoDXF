# Localization guide

Current web UI languages:

- `ko` — 한국어
- `en` — English
- `ja` — 日本語
- `es` — Español

## Rules

1. Browser language is used on first launch.
2. Manual language selection is stored in `localStorage`.
3. UI language must never enable/disable CAD font conversion.
4. Font conversion is based on drawing content, not UI language.
5. The former `KoreanOnly` mode is now `CjkOnly`.
6. CJK-only mode currently detects common BMP ranges for:
   - Hangul
   - Hiragana
   - Katakana
   - common Han / CJK Unified Ideographs
7. Shared DimensionStyle objects are intentionally not changed in CJK-only mode.

## Windows desktop version

When the Windows desktop build is localized later, keep the same four languages and the same three font modes:

- No conversion
- Replace all text (recommended)
- Replace CJK text only

The wording in `LocalizationService.cs` can be used as the shared translation baseline.
