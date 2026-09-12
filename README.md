# DWG2DXF

DWG 파일을 **브라우저에서 바로 DXF로 변환**하는 웹 도구입니다.

## ▶ 바로 실행

### [DWG2DXF Web 열기](https://bak2ya.github.io/DWGtoDXF/)

설치 없이 링크를 열고 DWG 파일을 추가한 뒤 변환하면 됩니다.  
DWG 파일은 서버로 업로드되지 않고 **사용자의 브라우저 안에서 로컬 처리**됩니다.

## 주요 기능

- macOS / Windows 브라우저에서 사용
- 여러 DWG 파일 선택
- DWG 헤더 사전 검사
- AutoCAD 2010 DXF 변환 또는 원본 DWG 버전 유지
- 글꼴 변환 3가지
  - 변환 안 함
  - 전체 문자 변경 **(권장)**
  - 한글 포함 문자만 변경
- `wqy-unicode.lff` 문자 스타일 적용
- 생성한 DXF를 다시 읽어 주요 객체 수 검증
- 변환 중 단계 진행률 및 작업 상태 표시
- 개별 DXF 다운로드
- 여러 결과를 ZIP으로 한 번에 다운로드
- 다크 모드
- LibreCAD용 `wqy-unicode.lff` 다운로드 및 설치 안내
- 원본 DWG는 수정하지 않음

## 사용 방법

1. [DWG2DXF Web](https://bak2ya.github.io/DWGtoDXF/)을 엽니다.
2. DWG 파일을 추가합니다.
3. 출력 DXF 버전과 글꼴 변환 방식을 선택합니다.
4. **DXF 변환**을 누릅니다.
5. 변환 및 재읽기 검증 결과를 확인합니다.
6. DXF 파일을 다운로드해 LibreCAD에서 엽니다.

## 변환 결과의 `확인 필요`

DWG와 생성된 DXF를 다시 읽어 주요 객체 수를 비교합니다.

객체 수에 차이가 있으면 변환 자체가 완료되었더라도 **확인 필요**로 표시합니다.  
이는 도면이 잘못되었다는 뜻이 아니라, 변환 전후에 차이가 감지되었으므로 LibreCAD에서 실제 형상을 확인하라는 안전 안내입니다.

Proxy / AEC / Civil 객체, XREF 및 일부 특수 객체는 완전한 변환을 보장하지 않습니다.

## LibreCAD 한글 글꼴

일부 DWG는 원본 CAD 글꼴을 LibreCAD에서 표시하지 못해 한글이 깨질 수 있습니다.

웹앱의 **추가기능 → LibreCAD 글꼴 설치 안내**에서 `wqy-unicode.lff`를 다운로드할 수 있습니다.

1. LibreCAD의 **응용프로그램 설정(Preferences) → 경로(Paths) → 글꼴(Fonts)**에서 글꼴 폴더를 확인합니다.
2. `wqy-unicode.lff`를 해당 폴더에 복사합니다.
3. LibreCAD를 완전히 종료합니다.
4. LibreCAD를 다시 실행합니다.

## 기술 구성

- .NET 8
- Blazor WebAssembly
- ACadSharp 3.6.51
- GitHub Pages

변환 처리는 WebAssembly 환경의 브라우저 내부에서 수행됩니다.

## 로컬 개발

.NET 8 SDK가 필요합니다.

```bash
dotnet restore src/DWG2DXF.Web/DWG2DXF.Web.csproj
dotnet run --project src/DWG2DXF.Web/DWG2DXF.Web.csproj
```

## GitHub Pages 배포

`main` 브랜치에 변경사항을 Push하면 GitHub Actions가 자동으로 빌드하고 GitHub Pages에 배포합니다.

배포 주소:

**https://bak2ya.github.io/DWGtoDXF/**

## 서드파티

- ACadSharp 3.6.51 — MIT License
- `wqy-unicode.lff` — Apache License 2.0 또는 GPLv3  
  이 프로젝트에서는 Apache License 2.0 조건으로 재배포합니다.

자세한 내용은 `THIRD_PARTY_NOTICES.txt` 및 프로젝트 내 라이선스 파일을 확인하세요.
