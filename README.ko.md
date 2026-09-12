# DWG2DXF

[English README](README.md)

DWG 파일을 LibreCAD에서 사용할 수 있는 DXF로 변환하는 도구입니다.

## 바로 사용하기

### 🌐 웹 버전
**https://bak2ya.github.io/DWGtoDXF/**

설치 없이 링크를 열면 됩니다. DWG 파일은 변환 서버로 업로드되지 않고 사용자의 브라우저 안에서 로컬로 처리됩니다.

### 🪟 Windows 앱
**https://github.com/Bak2ya/DWGtoDXF/releases**

Windows 데스크톱 버전은 GitHub Releases에서 배포합니다.

## 지원 언어

- 한국어
- English
- 日本語
- Español

처음 실행할 때 브라우저 언어를 자동으로 확인하고, 사용자가 직접 변경한 언어는 브라우저에 저장합니다.

UI 언어와 도면 안의 문자 언어는 서로 독립적입니다. 영어 UI를 사용해도 일본어/한국어가 들어간 DWG의 CJK 글꼴 변환 기능을 사용할 수 있습니다.

## 주요 기능

- 브라우저 안에서 DWG → DXF 변환
- macOS / Windows / Linux 브라우저 지원
- 여러 DWG 파일 변환
- DWG 헤더 사전 검사
- AutoCAD 2010 DXF 또는 원본 DWG 버전 유지
- 글꼴 변환 3가지
  - 변환 안 함
  - 전체 문자 `wqy-unicode` 적용 **(CJK 깨짐 문제에 권장)**
  - CJK 문자가 포함된 문자만 변경
- 한글, 히라가나, 가타카나, 일반적인 한자/CJK 문자 판별
- 생성한 DXF를 다시 읽어 주요 객체 수 비교
- 긴 작업 중 단계별 진행률과 동작 애니메이션
- 개별 DXF 다운로드
- 전체 결과 ZIP 다운로드
- 다크 모드
- LibreCAD용 `wqy-unicode.lff` 다운로드 및 설치 안내
- 원본 DWG는 수정하지 않음

## CJK 글꼴 변환

일부 DWG는 원본 CAD 글꼴을 LibreCAD에서 제대로 렌더링하지 못해 한국어·일본어·한자 등이 깨질 수 있습니다.

DWG2DXF는 필요한 경우 문자 스타일을 `wqy-unicode.lff`로 연결합니다.

CJK 전용 모드는 일반적으로 다음 문자를 판별합니다.

- 한글
- 히라가나
- 가타카나
- 일반적인 한자 / CJK Unified Ideographs

호환성이 가장 중요한 경우에는 **전체 문자 변경**을 권장합니다.

## `확인 필요`의 의미

변환 후 생성된 DXF를 다시 읽어 주요 객체 수를 원본과 비교합니다.

차이가 감지되면 변환이 완료되었더라도 **확인 필요**로 표시합니다. 이것은 도면이 손상되었다는 뜻이 아니라, LibreCAD에서 실제 형상을 한 번 확인하라는 안전 안내입니다.

Proxy / AEC / Civil / XREF 관련 객체 등 일부 특수 CAD 객체는 완전한 변환을 보장하지 않습니다.

## LibreCAD 글꼴 설치

웹앱에서 **추가기능 → LibreCAD 글꼴 설치 안내**를 엽니다.

1. `wqy-unicode.lff`를 다운로드합니다.
2. LibreCAD의 **응용프로그램 설정 → 경로 → 글꼴**에서 글꼴 폴더를 확인합니다.
3. 해당 폴더에 파일을 복사합니다.
4. LibreCAD를 완전히 종료합니다.
5. LibreCAD를 다시 실행합니다.

## 기술 구성

- .NET 8
- Blazor WebAssembly
- ACadSharp 3.6.51
- GitHub Pages

변환 처리는 WebAssembly를 이용해 브라우저 내부에서 수행됩니다.

## 소스 코드

소스 코드는 이 저장소에 함께 공개합니다.

**https://github.com/Bak2ya/DWGtoDXF**

현재 DWG2DXF 프로젝트 자체에 대한 별도 라이선스는 임의로 추가하지 않았습니다. 서드파티 구성요소의 라이선스 고지 파일은 저장소에 포함되어 있습니다.

## 로컬 개발

.NET 8 SDK가 필요합니다.

```bash
dotnet restore src/DWG2DXF.Web/DWG2DXF.Web.csproj
dotnet run --project src/DWG2DXF.Web/DWG2DXF.Web.csproj
```

## GitHub Pages 배포

`main` 브랜치에 Push하면 포함된 GitHub Actions가 자동으로 빌드하고 배포합니다.

웹앱:

**https://bak2ya.github.io/DWGtoDXF/**

## 서드파티

- ACadSharp 3.6.51 — MIT License
- `wqy-unicode.lff` — Apache License 2.0 또는 GPLv3  
  이 저장소에서는 Apache License 2.0 조건으로 재배포합니다.

자세한 내용은 `THIRD_PARTY_NOTICES.txt` 및 `wwwroot/assets/licenses/`의 파일을 확인하세요.
