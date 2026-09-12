# DWG2DXF Web v0.2 test checklist

## Deployment
- [ ] GitHub Actions build succeeds.
- [ ] https://bak2ya.github.io/DWGtoDXF/ opens correctly.
- [ ] Windows app link opens https://github.com/Bak2ya/DWGtoDXF/releases.
- [ ] Source code link opens the repository.

## Languages
Test all four UI languages:
- [ ] 한국어
- [ ] English
- [ ] 日本語
- [ ] Español

For each:
- [ ] Header/menu text changes.
- [ ] File validation messages change.
- [ ] Options and result labels change.
- [ ] About dialog changes.
- [ ] LibreCAD font guide changes.
- [ ] Manual language selection remains after refresh.

## DWG conversion
Use at least one real work DWG:
- [ ] DWG is recognized.
- [ ] Progress remains visibly active during long reads.
- [ ] AutoCAD 2010 DXF conversion completes.
- [ ] Generated DXF downloads.
- [ ] Re-read validation completes.
- [ ] LibreCAD opens the DXF.

## Font modes
- [ ] No conversion
- [ ] Replace all text
- [ ] CJK-only mode with Korean text
- [ ] CJK-only mode with Japanese Hiragana/Katakana
- [ ] CJK-only mode with Han/CJK characters
- [ ] Latin/numeric-only text remains unchanged in CJK-only mode where expected.

## Visual
- [ ] Light mode
- [ ] Dark mode, including page background
- [ ] Desktop layout
- [ ] Narrow/mobile layout

## Recommendation / guidance
- [ ] Korean defaults to Replace all text and marks it Recommended.
- [ ] Japanese defaults to Replace all text and marks it Recommended.
- [ ] English defaults to Do not convert and marks it Recommended.
- [ ] Spanish defaults to Do not convert and marks it Recomendado.
- [ ] CJK explanation is visible without opening a help dialog.
- [ ] Language (Language) control is clearly identifiable in the header.
