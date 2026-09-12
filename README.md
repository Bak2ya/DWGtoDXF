# DWG2DXF Web

브라우저 안에서 DWG 파일을 읽어 DXF로 변환하는 **DWG2DXF 웹/PWA 프로토타입**입니다.

기존 Windows용 DWG2DXF v1.2의 핵심 원칙을 유지하면서, WinForms/PowerShell 의존성을 제거하고 **Blazor WebAssembly + ACadSharp**로 재구성했습니다.

## 핵심 특징

- DWG 파일은 서버에 업로드하지 않고 **브라우저 메모리에서 로컬 처리**합니다.
- 여러 DWG 파일 선택/드래그앤드롭
- 6바이트 DWG 헤더 사전 검사
- 출력 버전
  - AutoCAD 2010 DXF (AC1024, 권장)
  - 원본 DWG 버전 유지
- 글꼴 변환 3모드
  - 변환 안 함
  - 전체 문자 변경 (권장)
  - 한글 포함 문자만 변경
- `wqy-unicode.lff` 스타일 자동 연결
- 변환 후 생성 DXF를 다시 읽고 주요 객체 수를 비교
- 개별 DXF 다운로드 / 변환 완료 파일 전체 ZIP 다운로드
- 다크 모드 저장
- LibreCAD 폰트 설치 안내 및 `wqy-unicode.lff` 다운로드
- PWA 설치 지원
- GitHub Pages 자동 배포 Workflow 포함

## 중요: 현재 상태

이 저장소는 **웹 이식 첫 버전**입니다. ACadSharp 3.6.51은 `net8.0-browser` 호환 대상으로 계산되며 Stream 기반 DWG/DXF 입출력을 지원하지만, 실제 WebAssembly 환경에서 모든 업체/버전의 DWG가 정상 처리되는지는 반드시 업무용 샘플 파일로 회귀 테스트해야 합니다.

특히 Proxy/AEC/Civil 객체, XREF, 특수 객체는 기존 데스크톱판과 마찬가지로 완전 보존을 보장하지 않습니다. 변환 후 `확인 필요` 결과가 나오면 LibreCAD에서 도면을 직접 확인하세요.

## 로컬 실행

필요사항: .NET 8 SDK

```bash
dotnet restore src/DWG2DXF.Web/DWG2DXF.Web.csproj
dotnet run --project src/DWG2DXF.Web/DWG2DXF.Web.csproj
```

브라우저에 표시되는 로컬 주소로 접속합니다.

## GitHub에 올리기

```bash
git init
git add .
git commit -m "Initial DWG2DXF Web prototype"
git branch -M main
git remote add origin https://github.com/<YOUR_ID>/<YOUR_REPO>.git
git push -u origin main
```

### GitHub Pages 배포

1. GitHub 저장소의 **Settings → Pages**로 이동합니다.
2. **Build and deployment → Source**를 `GitHub Actions`로 선택합니다.
3. `main` 브랜치에 push하면 `.github/workflows/deploy-pages.yml`이 자동 빌드/배포합니다.

Workflow가 저장소 이름에 맞게 `<base href>`를 자동 수정하므로 프로젝트 페이지(`/repository-name/`)에서도 동작하도록 구성했습니다.

## LibreCAD 한글 폰트

웹 브라우저는 보안상 사용자의 LibreCAD 설치 폴더를 직접 열 수 없습니다. 앱의 **추가기능 → LibreCAD 글꼴 설치 안내**에서 `wqy-unicode.lff`를 내려받은 뒤 LibreCAD의 글꼴 폴더에 직접 복사합니다.

일반적인 Windows 설치 위치 예:

- `C:\Program Files\LibreCAD\resources\fonts`
- `C:\Program Files\LibreCAD\share\librecad\fonts`

정확한 위치는 LibreCAD에서 **옵션 → 응용프로그램 설정 → 경로 → 글꼴**을 확인하세요. 파일 복사 후 LibreCAD를 완전히 종료했다가 다시 실행합니다.

## 원본 보호

웹 버전은 원본 DWG를 수정하지 않습니다. 변환 결과는 브라우저 다운로드로만 제공합니다.

## 라이선스/서드파티

- ACadSharp 3.6.51 — MIT License
- `wqy-unicode.lff` — Apache License 2.0 또는 GPLv3 중, 이 프로젝트에서는 Apache License 2.0 조건으로 재배포

자세한 고지는 `THIRD_PARTY_NOTICES.txt`와 `wwwroot/assets/licenses/`를 확인하세요.

> 이 저장소 자체의 소스 코드 라이선스는 별도로 지정하지 않았습니다. 공개 저장소로 배포하면서 재사용을 허용하려면 원하는 라이선스를 추가하세요.
