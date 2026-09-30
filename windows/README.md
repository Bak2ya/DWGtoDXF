# DWG2DXF Windows v1.3

Windows용 DWG → DXF 변환기 소스/빌드 키트입니다.

## v1.3 주요 변경사항

- 한국어 / English / 日本語 / Español UI
- **첫 실행 시 Windows 표시 언어 자동 감지**
  - 한국어 Windows → 한국어
  - 일본어 Windows → 日本語
  - 스페인어 Windows → Español
  - 그 외 → English
- `추가기능 → 언어 (Language)`에서 언제든 수동 변경 가능
- 수동으로 고른 언어는 저장되어 이후 실행에서 우선 적용
- 기존 `한글 포함 문자만 변경`을 **한·중·일(CJK) 문자만 변경**으로 확장
- CJK가 Chinese / Japanese / Korean 문자라는 설명을 폰트 옵션 바로 아래에 항상 표시
- 한글 / 히라가나 / 가타카나 / 일반적인 한자·CJK 범위 감지
- UI 언어와 도면 문자 언어는 독립적이므로 모든 언어에서 세 가지 폰트 옵션을 사용할 수 있음

## 언어별 기본 폰트 권장값

폰트 변환 기능은 LibreCAD에서 한글·일본어·한자 등 CJK 문자가 깨져 보이는 문제를 보완하기 위한 기능입니다.

- **한국어 / 일본어 UI**
  - 기본 선택: `전체 문자 변경 (권장)`
  - CJK 도면 호환성을 가장 우선하는 설정
- **영어 / 스페인어 UI**
  - 기본 선택: `변환 안 함 / Keep original (Recommended)`
  - CJK 표시 문제가 없다면 원본 문자 스타일을 유지하는 방향

모든 언어에서 다음 세 옵션은 그대로 제공됩니다.

1. 변환 안 함
2. 전체 문자 변경
3. 한·중·일(CJK) 문자만 변경

CJK 전용 모드는 영문·숫자는 가능한 한 원본 스타일을 유지하면서 한글, 일본어 가나, 한자 등 CJK 문자가 포함된 문자만 `wqy-unicode`로 연결합니다.

## 기존 기능 유지

- 원본 DWG 보호
- DXF 덮어쓰기 방지
- AutoCAD 2010 DXF 권장 출력
- 변환 후 DXF 재읽기 검증
- 다크 모드
- 저장폴더 변경
- LibreCAD `wqy-unicode.lff` 저장/폰트 폴더 열기
- 변환 단계별 진행률 표시
- 출력 파일 충돌 시 `_converted`, `_converted_2` 형식 사용

## 빌드

Windows 10/11 PC에서:

1. ZIP 압축 해제
2. `BUILD_v1.3.cmd` 더블클릭
3. 빌드 완료 후 `dist\DWG2DXF_v1.3.exe` 확인

요구사항:

- .NET Framework 4.8 이상
- Windows PowerShell 5.1
- 첫 빌드 시 인터넷 연결
- 관리자 권한 불필요

완성된 EXE 하나에 변환 엔진, 필요한 DLL, `wqy-unicode.lff`, 아이콘, 라이선스 고지가 내장됩니다.

## 배포

`dist\DWG2DXF_v1.3.exe` 하나를 GitHub Releases에 첨부하면 됩니다.

웹 버전: https://bak2ya.github.io/DWGtoDXF/

소스 저장소: https://github.com/Bak2ya/DWGtoDXF
