using System.Globalization;

namespace DWG2DXF.Web.Services;

public sealed class LocalizationService
{
    private const string DefaultLanguage = "en";

    private static readonly IReadOnlyDictionary<string, IReadOnlyDictionary<string, string>> Strings =
        new Dictionary<string, IReadOnlyDictionary<string, string>>(StringComparer.OrdinalIgnoreCase)
        {
            ["en"] = En(),
            ["ko"] = Ko(),
            ["ja"] = Ja(),
            ["es"] = Es()
        };

    public string CurrentCode { get; private set; } = DefaultLanguage;

    public void SetLanguage(string? code)
    {
        var normalized = Normalize(code);
        CurrentCode = Strings.ContainsKey(normalized) ? normalized : DefaultLanguage;
    }

    public string Get(string key)
    {
        if (Strings.TryGetValue(CurrentCode, out var current) && current.TryGetValue(key, out var value))
            return value;

        if (Strings[DefaultLanguage].TryGetValue(key, out var fallback))
            return fallback;

        return key;
    }

    public string T(string key, params object[] args)
    {
        var template = Get(key);
        return args.Length == 0
            ? template
            : string.Format(CultureInfo.CurrentCulture, template, args);
    }

    public static string Normalize(string? code)
    {
        if (string.IsNullOrWhiteSpace(code))
            return DefaultLanguage;

        code = code.Trim().ToLowerInvariant();

        if (code.StartsWith("ko")) return "ko";
        if (code.StartsWith("ja")) return "ja";
        if (code.StartsWith("es")) return "es";
        return "en";
    }

    private static Dictionary<string, string> En() => new(StringComparer.Ordinal)
    {
        ["meta.description"] = "Convert DWG files to DXF locally in your browser.",

        ["language.label"] = "Language",
        ["language.menu"] = "Language",
        ["windows.app"] = "Windows app",
        ["source.code"] = "Source code",
        ["menu.more"] = "More",
        ["menu.about"] = "About",
        ["menu.darkMode"] = "Dark mode",
        ["menu.on"] = "On",
        ["menu.off"] = "Off",
        ["menu.fontGuide"] = "LibreCAD font guide",
        ["engine.status"] = "Local browser conversion · ACadSharp 3.6.51",

        ["drop.title"] = "Drop DWG files here or click to add",
        ["drop.subtitle"] = "Files are processed only in this browser and are not uploaded to a server.",
        ["files.empty"] = "No DWG files have been added.",
        ["files.add"] = "Add files",
        ["files.removeErrors"] = "Remove error files",
        ["files.clear"] = "Clear all",
        ["files.removeTitle"] = "Remove from list",

        ["option.output.title"] = "Output DXF version",
        ["option.output.desc"] = "AutoCAD 2010 DXF is recommended for LibreCAD compatibility.",
        ["option.output.2010"] = "AutoCAD 2010 DXF (Recommended)",
        ["option.output.original"] = "Keep original DWG version",

        ["option.font.title"] = "Font conversion",
        ["option.font.desc"] = "Font conversion is optional and is mainly intended for CJK text compatibility in LibreCAD.",
        ["font.none"] = "Do not convert",
        ["font.all"] = "Replace all text",
        ["font.cjk"] = "Replace CJK text only",
        ["font.recommended"] = "Recommended",
        ["font.cjkTitle"] = "What is CJK?",
        ["font.cjkHelp"] = "CJK means Chinese, Japanese, and Korean characters. Use font conversion when CJK text appears garbled in LibreCAD. If text already displays correctly, Do not convert is recommended.",
        ["font.cjkDetail"] = "Only text containing Chinese, Japanese, or Korean characters is changed. Latin letters and numbers keep their original styles when possible.",
        ["font.cjkWarning"] = "CJK-only conversion may miss some shared or special text styles in certain drawings.",

        ["convert.button"] = "Convert to DXF",
        ["convert.running"] = "Converting",
        ["log.empty"] = "Conversion logs will appear here.",
        ["results.title"] = "Conversion results",
        ["results.downloadZip"] = "Download all as ZIP",
        ["results.review"] = "Review recommended",
        ["results.verified"] = "Conversion/re-read validation passed",
        ["results.objects"] = "objects",
        ["results.layers"] = "layers",
        ["results.text"] = "text",
        ["results.downloadDxf"] = "Download DXF",

        ["footer.original"] = "Original DWG files are never modified.",
        ["footer.download"] = "Results are saved only through browser downloads.",

        ["about.title"] = "DWG2DXF Web",
        ["about.intro"] = "A small preprocessing tool that converts DWG files to DXF so they can be reviewed and edited in LibreCAD without requiring AutoCAD.",
        ["about.useTitle"] = "How to use",
        ["about.step1"] = "Add one or more DWG files.",
        ["about.step2"] = "Choose the DXF version and font conversion mode.",
        ["about.step3"] = "Select Convert to DXF.",
        ["about.step4"] = "Review the re-read validation result and download the DXF.",
        ["about.step5"] = "Open the result in LibreCAD and visually confirm the drawing.",
        ["about.notice"] = "This is not a CAD editor. Proxy/AEC/Civil and other special objects are not guaranteed to convert perfectly, and object-count validation does not prove mathematical equivalence.",
        ["about.platforms"] = "Use this web version on macOS, Windows, or Linux. A Windows desktop build is also available from GitHub Releases.",
        ["about.version"] = "Web v0.3 · ACadSharp 3.6.51",

        ["fontGuide.title"] = "LibreCAD font installation",
        ["fontGuide.intro"] = "Browsers cannot open the LibreCAD installation folder directly. Download the font below and copy it to LibreCAD's font folder.",
        ["fontGuide.download"] = "Download wqy-unicode.lff",
        ["fontGuide.platform"] = "Windows / macOS",
        ["fontGuide.step1"] = "In LibreCAD, open Application Preferences → Paths → Fonts and check the current font folder.",
        ["fontGuide.step2"] = "Copy the downloaded wqy-unicode.lff into that folder.",
        ["fontGuide.step3"] = "Quit LibreCAD completely.",
        ["fontGuide.step4"] = "Launch LibreCAD again.",
        ["fontGuide.windowsPath"] = "Common Windows locations:",
        ["fontGuide.macPath"] = "On macOS, use the font path shown in LibreCAD Preferences.",
        ["fontGuide.license"] = "Font license: Apache License 2.0 or GPLv3. This project redistributes it under Apache License 2.0 terms.",

        ["status.waiting"] = "Waiting",
        ["status.checking"] = "Checking",
        ["status.ready"] = "Ready",
        ["status.error"] = "Error",
        ["status.done"] = "Done",
        ["status.review"] = "Review",
        ["status.failed"] = "Failed",

        ["progress.preparing"] = "Preparing conversion",
        ["progress.loading"] = "Loading DWG",
        ["progress.analyzing"] = "Analyzing DWG structure",
        ["progress.inspecting"] = "Checking objects",
        ["progress.output"] = "Applying output settings",
        ["progress.fontCheck"] = "Checking font settings",
        ["progress.fontConvert"] = "Converting fonts",
        ["progress.generating"] = "Generating DXF",
        ["progress.verifying"] = "Re-reading DXF for validation",
        ["progress.summarizing"] = "Preparing validation result",
        ["progress.done"] = "Done",

        ["validation.notDwg"] = "Only DWG files can be added.",
        ["validation.invalidHeader"] = "The DWG file header is invalid.",
        ["validation.tooLarge"] = "The current web version supports files up to {0} MB each.",
        ["validation.unrecognized"] = "The file is not recognized as a DWG.",
        ["validation.oldVersion"] = "This old DWG version is not supported by the current conversion engine. ({0})",
        ["validation.checkFailed"] = "File check failed: {0}",

        ["error.readDwg"] = "The DWG document could not be read.",
        ["error.emptyDxf"] = "The DXF file was not generated.",
        ["error.verifyDxf"] = "The generated DXF could not be re-read for validation.",

        ["log.start"] = "Starting conversion. All processing stays inside this browser.",
        ["log.reading"] = "Reading {0}...",
        ["log.analyzing"] = "Analyzing DWG structure...",
        ["log.output2010"] = "Output version: AutoCAD 2010 DXF (AC1024)",
        ["log.outputOriginal"] = "Output version: keep original ({0})",
        ["log.fontAll"] = "Font: applied wqy-unicode to all text (text {0}, attributes {1}, dimension styles {2})",
        ["log.fontCjk"] = "Font: applied wqy-unicode only to text containing CJK characters (text {0}, attributes {1})",
        ["log.fontCjkNone"] = "Font: no CJK text found; original text styles were kept.",
        ["log.fontNone"] = "Font: no conversion (original text styles kept)",
        ["log.generating"] = "Generating DXF...",
        ["log.generated"] = "DXF generated: {0:N0} bytes · validating by re-reading...",
        ["log.fontVerified"] = "Font validation: wqy-unicode style OK (text {0}, dimension styles {1})",
        ["log.resultReview"] = "Conversion completed; review recommended: {0} · {1}",
        ["log.resultOk"] = "Conversion/re-read validation passed: {0} (objects {1}, layers {2}, text {3})",
        ["log.failure"] = "Conversion failed: {0}",
        ["log.summary"] = "Done · OK {0} · Review {1} · Failed {2}",

        ["difference.fontStyleMissing"] = "wqy-unicode style was not saved in the DXF",
        ["difference.fontUsageZero"] = "wqy-unicode text style usage is 0"
    };

    private static Dictionary<string, string> Ko() => new(StringComparer.Ordinal)
    {
        ["meta.description"] = "DWG 파일을 서버 업로드 없이 브라우저에서 로컬로 DXF로 변환합니다.",

        ["language.label"] = "언어",
        ["language.menu"] = "언어 (Language)",
        ["windows.app"] = "Windows 앱",
        ["source.code"] = "소스 코드",
        ["menu.more"] = "추가기능",
        ["menu.about"] = "프로그램 설명",
        ["menu.darkMode"] = "다크 모드",
        ["menu.on"] = "켜짐",
        ["menu.off"] = "꺼짐",
        ["menu.fontGuide"] = "LibreCAD 글꼴 설치 안내",
        ["engine.status"] = "브라우저 로컬 변환 · ACadSharp 3.6.51",

        ["drop.title"] = "DWG 파일을 여기에 놓거나 클릭해서 추가하세요",
        ["drop.subtitle"] = "파일은 서버로 전송되지 않고 이 브라우저에서만 처리됩니다.",
        ["files.empty"] = "추가된 DWG 파일이 없습니다.",
        ["files.add"] = "파일 추가",
        ["files.removeErrors"] = "오류 파일 삭제",
        ["files.clear"] = "전체 삭제",
        ["files.removeTitle"] = "목록에서 삭제",

        ["option.output.title"] = "출력 DXF 버전",
        ["option.output.desc"] = "LibreCAD 호환성을 위해 AutoCAD 2010 DXF를 권장합니다.",
        ["option.output.2010"] = "AutoCAD 2010 DXF (권장)",
        ["option.output.original"] = "원본 DWG 버전 유지",

        ["option.font.title"] = "글꼴 변환",
        ["option.font.desc"] = "LibreCAD에서 한글·일본어·한자 등이 깨져 보이는 경우를 위한 선택 기능입니다.",
        ["font.none"] = "변환 안 함",
        ["font.all"] = "전체 문자 변경",
        ["font.cjk"] = "한·중·일(CJK) 문자만 변경",
        ["font.recommended"] = "권장",
        ["font.cjkTitle"] = "CJK란?",
        ["font.cjkHelp"] = "CJK는 중국어·일본어·한국어 문자를 뜻합니다. LibreCAD에서 관련 문자가 깨지는 경우 글꼴 변환을 사용할 수 있으며, 호환성이 중요하면 전체 문자 변경이 가장 안정적입니다.",
        ["font.cjkDetail"] = "한글, 히라가나, 가타카나, 한자 등이 포함된 문자만 변경하고 영문·숫자는 가능한 원본 스타일을 유지합니다.",
        ["font.cjkWarning"] = "일부 도면에서는 공유 문자 스타일이나 특수 객체 때문에 CJK 문자만 정확히 분리되지 않을 수 있습니다.",

        ["convert.button"] = "DXF 변환",
        ["convert.running"] = "변환 중",
        ["log.empty"] = "변환 로그가 여기에 표시됩니다.",
        ["results.title"] = "변환 결과",
        ["results.downloadZip"] = "전체 ZIP 다운로드",
        ["results.review"] = "확인 필요",
        ["results.verified"] = "변환/재읽기 검증 통과",
        ["results.objects"] = "객체",
        ["results.layers"] = "레이어",
        ["results.text"] = "문자",
        ["results.downloadDxf"] = "DXF 다운로드",

        ["footer.original"] = "원본 DWG는 수정하지 않습니다.",
        ["footer.download"] = "결과 파일은 브라우저 다운로드로만 저장됩니다.",

        ["about.title"] = "DWG2DXF Web",
        ["about.intro"] = "AutoCAD 없이 DWG를 DXF로 변환해 LibreCAD에서 확인·수정할 수 있도록 만든 작은 전처리 도구입니다.",
        ["about.useTitle"] = "사용 순서",
        ["about.step1"] = "DWG 파일을 추가합니다.",
        ["about.step2"] = "DXF 버전과 글꼴 변환 방식을 선택합니다.",
        ["about.step3"] = "DXF 변환을 누릅니다.",
        ["about.step4"] = "재읽기 검증 결과를 확인하고 DXF를 다운로드합니다.",
        ["about.step5"] = "LibreCAD에서 결과 도면을 열어 실제 형상을 최종 확인합니다.",
        ["about.notice"] = "이 도구는 CAD 편집기가 아닙니다. Proxy/AEC/Civil 등 특수 객체는 완벽한 변환을 보장하지 않으며, 객체 수 검증도 수학적 동일성을 증명하는 기능은 아닙니다.",
        ["about.platforms"] = "웹 버전은 macOS, Windows, Linux에서 사용할 수 있습니다. Windows 데스크톱 버전은 GitHub Releases에서도 받을 수 있습니다.",
        ["about.version"] = "Web v0.3 · ACadSharp 3.6.51",

        ["fontGuide.title"] = "LibreCAD 글꼴 설치 안내",
        ["fontGuide.intro"] = "브라우저는 보안상 LibreCAD 설치 폴더를 직접 열 수 없습니다. 아래 글꼴 파일을 받은 뒤 LibreCAD 글꼴 폴더에 직접 복사하세요.",
        ["fontGuide.download"] = "wqy-unicode.lff 다운로드",
        ["fontGuide.platform"] = "Windows / macOS",
        ["fontGuide.step1"] = "LibreCAD에서 응용프로그램 설정(Preferences) → 경로(Paths) → 글꼴(Fonts)을 열어 현재 글꼴 폴더를 확인합니다.",
        ["fontGuide.step2"] = "다운로드한 wqy-unicode.lff를 해당 폴더로 복사합니다.",
        ["fontGuide.step3"] = "LibreCAD를 완전히 종료합니다.",
        ["fontGuide.step4"] = "LibreCAD를 다시 실행합니다.",
        ["fontGuide.windowsPath"] = "Windows 일반적인 위치:",
        ["fontGuide.macPath"] = "macOS에서는 LibreCAD 설정에 표시되는 글꼴 경로를 사용하세요.",
        ["fontGuide.license"] = "글꼴 라이선스: Apache License 2.0 또는 GPLv3. 이 프로젝트에서는 Apache License 2.0 조건으로 재배포합니다.",

        ["status.waiting"] = "대기",
        ["status.checking"] = "검사 중",
        ["status.ready"] = "준비",
        ["status.error"] = "오류",
        ["status.done"] = "완료",
        ["status.review"] = "확인 필요",
        ["status.failed"] = "실패",

        ["progress.preparing"] = "변환 준비 중",
        ["progress.loading"] = "DWG 불러오는 중",
        ["progress.analyzing"] = "DWG 구조 분석 중",
        ["progress.inspecting"] = "객체 정보 확인 중",
        ["progress.output"] = "출력 설정 적용 중",
        ["progress.fontCheck"] = "글꼴 설정 확인 중",
        ["progress.fontConvert"] = "글꼴 변환 중",
        ["progress.generating"] = "DXF 생성 중",
        ["progress.verifying"] = "DXF 재읽기 검증 중",
        ["progress.summarizing"] = "검증 결과 정리 중",
        ["progress.done"] = "완료",

        ["validation.notDwg"] = "DWG 파일만 추가할 수 있습니다.",
        ["validation.invalidHeader"] = "DWG 파일 헤더가 올바르지 않습니다.",
        ["validation.tooLarge"] = "현재 웹 버전의 단일 파일 제한은 {0} MB입니다.",
        ["validation.unrecognized"] = "DWG 형식으로 인식할 수 없습니다.",
        ["validation.oldVersion"] = "현재 변환 엔진에서 지원하지 않는 오래된 DWG 버전입니다. ({0})",
        ["validation.checkFailed"] = "파일 확인 실패: {0}",

        ["error.readDwg"] = "DWG 문서를 읽지 못했습니다.",
        ["error.emptyDxf"] = "DXF 파일이 생성되지 않았습니다.",
        ["error.verifyDxf"] = "생성된 DXF를 다시 읽어 검증하지 못했습니다.",

        ["log.start"] = "변환을 시작합니다. 모든 처리는 이 브라우저 안에서 진행됩니다.",
        ["log.reading"] = "{0} 읽는 중...",
        ["log.analyzing"] = "DWG 구조 분석 중...",
        ["log.output2010"] = "출력 버전: AutoCAD 2010 DXF (AC1024)",
        ["log.outputOriginal"] = "출력 버전: 원본 유지 ({0})",
        ["log.fontAll"] = "글꼴: 전체 문자 wqy-unicode 적용 (문자 {0}, 속성 {1}, 치수스타일 {2})",
        ["log.fontCjk"] = "글꼴: CJK 포함 문자만 wqy-unicode 적용 (문자 {0}, 속성 {1})",
        ["log.fontCjkNone"] = "글꼴: CJK 문자를 찾지 못해 원본 문자 스타일을 유지했습니다.",
        ["log.fontNone"] = "글꼴: 변환하지 않음 (원본 문자 스타일 유지)",
        ["log.generating"] = "DXF 생성 중...",
        ["log.generated"] = "DXF 생성 완료: {0:N0} bytes · 재읽기 검증 중...",
        ["log.fontVerified"] = "글꼴 재검증: wqy-unicode 스타일 정상 (문자 {0}, 치수스타일 {1})",
        ["log.resultReview"] = "변환 완료, 확인 필요: {0} · {1}",
        ["log.resultOk"] = "변환/재읽기 검증 통과: {0} (객체 {1}, 레이어 {2}, 문자 {3})",
        ["log.failure"] = "변환 실패: {0}",
        ["log.summary"] = "완료 · 정상 {0} · 확인 필요 {1} · 실패 {2}",

        ["difference.fontStyleMissing"] = "wqy-unicode 스타일이 DXF에 저장되지 않음",
        ["difference.fontUsageZero"] = "wqy-unicode 문자 스타일 적용 0건"
    };

    private static Dictionary<string, string> Ja() => new(StringComparer.Ordinal)
    {
        ["meta.description"] = "DWGファイルをサーバーへ送信せず、ブラウザ内でDXFに変換します。",

        ["language.label"] = "言語",
        ["language.menu"] = "言語 (Language)",
        ["windows.app"] = "Windows版",
        ["source.code"] = "ソースコード",
        ["menu.more"] = "その他",
        ["menu.about"] = "このツールについて",
        ["menu.darkMode"] = "ダークモード",
        ["menu.on"] = "オン",
        ["menu.off"] = "オフ",
        ["menu.fontGuide"] = "LibreCAD フォント設定",
        ["engine.status"] = "ブラウザ内ローカル変換 · ACadSharp 3.6.51",

        ["drop.title"] = "DWGファイルをここにドロップするか、クリックして追加",
        ["drop.subtitle"] = "ファイルはサーバーへ送信されず、このブラウザ内でのみ処理されます。",
        ["files.empty"] = "DWGファイルが追加されていません。",
        ["files.add"] = "ファイル追加",
        ["files.removeErrors"] = "エラーファイルを削除",
        ["files.clear"] = "すべて削除",
        ["files.removeTitle"] = "一覧から削除",

        ["option.output.title"] = "出力DXFバージョン",
        ["option.output.desc"] = "LibreCADとの互換性のため AutoCAD 2010 DXF を推奨します。",
        ["option.output.2010"] = "AutoCAD 2010 DXF（推奨）",
        ["option.output.original"] = "元のDWGバージョンを維持",

        ["option.font.title"] = "フォント変換",
        ["option.font.desc"] = "LibreCADでハングル・かな・漢字などが文字化けする場合のためのオプションです。",
        ["font.none"] = "変換しない",
        ["font.all"] = "すべての文字を変更",
        ["font.cjk"] = "CJK文字のみ変更",
        ["font.recommended"] = "推奨",
        ["font.cjkTitle"] = "CJKとは？",
        ["font.cjkHelp"] = "CJKは中国語・日本語・韓国語の文字を意味します。LibreCADで関連文字が文字化けする場合に使用し、互換性を優先する場合は「すべての文字を変更」が最も安定します。",
        ["font.cjkDetail"] = "ハングル、ひらがな、カタカナ、漢字などを含むテキストのみ変更し、英数字は可能な限り元のスタイルを維持します。",
        ["font.cjkWarning"] = "一部の図面では共有文字スタイルや特殊オブジェクトのため、CJK文字だけを正確に分離できない場合があります。",

        ["convert.button"] = "DXFに変換",
        ["convert.running"] = "変換中",
        ["log.empty"] = "変換ログがここに表示されます。",
        ["results.title"] = "変換結果",
        ["results.downloadZip"] = "すべてZIPでダウンロード",
        ["results.review"] = "要確認",
        ["results.verified"] = "変換・再読み込み検証済み",
        ["results.objects"] = "オブジェクト",
        ["results.layers"] = "レイヤー",
        ["results.text"] = "文字",
        ["results.downloadDxf"] = "DXFをダウンロード",

        ["footer.original"] = "元のDWGファイルは変更しません。",
        ["footer.download"] = "結果はブラウザのダウンロード機能でのみ保存されます。",

        ["about.title"] = "DWG2DXF Web",
        ["about.intro"] = "AutoCADを必要とせず、DWGをDXFへ変換してLibreCADで確認・編集するための小さな前処理ツールです。",
        ["about.useTitle"] = "使い方",
        ["about.step1"] = "DWGファイルを追加します。",
        ["about.step2"] = "DXFバージョンとフォント変換方法を選択します。",
        ["about.step3"] = "DXFに変換を選択します。",
        ["about.step4"] = "再読み込み検証結果を確認し、DXFをダウンロードします。",
        ["about.step5"] = "LibreCADで結果を開き、図面を目視で最終確認します。",
        ["about.notice"] = "このツールはCADエディターではありません。Proxy/AEC/Civilなどの特殊オブジェクトは完全な変換を保証できず、オブジェクト数の検証も数学的な同一性を証明するものではありません。",
        ["about.platforms"] = "Web版はmacOS、Windows、Linuxで利用できます。Windowsデスクトップ版はGitHub Releasesからも入手できます。",
        ["about.version"] = "Web v0.3 · ACadSharp 3.6.51",

        ["fontGuide.title"] = "LibreCAD フォント設定",
        ["fontGuide.intro"] = "ブラウザからLibreCADのインストールフォルダを直接開くことはできません。下のフォントをダウンロードし、LibreCADのフォントフォルダへコピーしてください。",
        ["fontGuide.download"] = "wqy-unicode.lff をダウンロード",
        ["fontGuide.platform"] = "Windows / macOS",
        ["fontGuide.step1"] = "LibreCADで Application Preferences → Paths → Fonts を開き、現在のフォントフォルダを確認します。",
        ["fontGuide.step2"] = "ダウンロードした wqy-unicode.lff をそのフォルダへコピーします。",
        ["fontGuide.step3"] = "LibreCADを完全に終了します。",
        ["fontGuide.step4"] = "LibreCADを再起動します。",
        ["fontGuide.windowsPath"] = "Windowsで一般的な場所:",
        ["fontGuide.macPath"] = "macOSではLibreCADの設定に表示されるフォントパスを使用してください。",
        ["fontGuide.license"] = "フォントライセンス: Apache License 2.0 または GPLv3。本プロジェクトでは Apache License 2.0 の条件で再配布します。",

        ["status.waiting"] = "待機",
        ["status.checking"] = "確認中",
        ["status.ready"] = "準備完了",
        ["status.error"] = "エラー",
        ["status.done"] = "完了",
        ["status.review"] = "要確認",
        ["status.failed"] = "失敗",

        ["progress.preparing"] = "変換準備中",
        ["progress.loading"] = "DWG読み込み中",
        ["progress.analyzing"] = "DWG構造を解析中",
        ["progress.inspecting"] = "オブジェクトを確認中",
        ["progress.output"] = "出力設定を適用中",
        ["progress.fontCheck"] = "フォント設定を確認中",
        ["progress.fontConvert"] = "フォント変換中",
        ["progress.generating"] = "DXF生成中",
        ["progress.verifying"] = "DXFを再読み込みして検証中",
        ["progress.summarizing"] = "検証結果を整理中",
        ["progress.done"] = "完了",

        ["validation.notDwg"] = "DWGファイルのみ追加できます。",
        ["validation.invalidHeader"] = "DWGファイルのヘッダーが正しくありません。",
        ["validation.tooLarge"] = "現在のWeb版では1ファイルあたり最大 {0} MB まで対応します。",
        ["validation.unrecognized"] = "DWG形式として認識できません。",
        ["validation.oldVersion"] = "現在の変換エンジンでは対応していない古いDWGバージョンです。({0})",
        ["validation.checkFailed"] = "ファイル確認に失敗しました: {0}",

        ["error.readDwg"] = "DWGドキュメントを読み込めませんでした。",
        ["error.emptyDxf"] = "DXFファイルを生成できませんでした。",
        ["error.verifyDxf"] = "生成したDXFを再読み込みして検証できませんでした。",

        ["log.start"] = "変換を開始します。すべての処理はこのブラウザ内で行われます。",
        ["log.reading"] = "{0} を読み込み中...",
        ["log.analyzing"] = "DWG構造を解析中...",
        ["log.output2010"] = "出力バージョン: AutoCAD 2010 DXF (AC1024)",
        ["log.outputOriginal"] = "出力バージョン: 元のバージョンを維持 ({0})",
        ["log.fontAll"] = "フォント: すべての文字に wqy-unicode を適用（文字 {0}、属性 {1}、寸法スタイル {2}）",
        ["log.fontCjk"] = "フォント: CJK文字を含むテキストのみに wqy-unicode を適用（文字 {0}、属性 {1}）",
        ["log.fontCjkNone"] = "フォント: CJK文字が見つからなかったため、元の文字スタイルを維持しました。",
        ["log.fontNone"] = "フォント: 変換しない（元の文字スタイルを維持）",
        ["log.generating"] = "DXF生成中...",
        ["log.generated"] = "DXF生成完了: {0:N0} bytes · 再読み込み検証中...",
        ["log.fontVerified"] = "フォント再検証: wqy-unicode スタイル正常（文字 {0}、寸法スタイル {1}）",
        ["log.resultReview"] = "変換完了・要確認: {0} · {1}",
        ["log.resultOk"] = "変換・再読み込み検証済み: {0}（オブジェクト {1}、レイヤー {2}、文字 {3}）",
        ["log.failure"] = "変換失敗: {0}",
        ["log.summary"] = "完了 · 正常 {0} · 要確認 {1} · 失敗 {2}",

        ["difference.fontStyleMissing"] = "wqy-unicode スタイルがDXFに保存されていません",
        ["difference.fontUsageZero"] = "wqy-unicode 文字スタイルの適用件数が0です"
    };

    private static Dictionary<string, string> Es() => new(StringComparer.Ordinal)
    {
        ["meta.description"] = "Convierte archivos DWG a DXF localmente en el navegador, sin subirlos a un servidor.",

        ["language.label"] = "Idioma",
        ["language.menu"] = "Idioma (Language)",
        ["windows.app"] = "App para Windows",
        ["source.code"] = "Código fuente",
        ["menu.more"] = "Más",
        ["menu.about"] = "Acerca del programa",
        ["menu.darkMode"] = "Modo oscuro",
        ["menu.on"] = "Activado",
        ["menu.off"] = "Desactivado",
        ["menu.fontGuide"] = "Guía de fuentes de LibreCAD",
        ["engine.status"] = "Conversión local en el navegador · ACadSharp 3.6.51",

        ["drop.title"] = "Arrastra archivos DWG aquí o haz clic para añadirlos",
        ["drop.subtitle"] = "Los archivos no se suben a ningún servidor; se procesan únicamente en este navegador.",
        ["files.empty"] = "No se han añadido archivos DWG.",
        ["files.add"] = "Añadir archivos",
        ["files.removeErrors"] = "Eliminar archivos con error",
        ["files.clear"] = "Eliminar todo",
        ["files.removeTitle"] = "Quitar de la lista",

        ["option.output.title"] = "Versión DXF de salida",
        ["option.output.desc"] = "Se recomienda AutoCAD 2010 DXF para una mejor compatibilidad con LibreCAD.",
        ["option.output.2010"] = "AutoCAD 2010 DXF (Recomendado)",
        ["option.output.original"] = "Mantener la versión DWG original",

        ["option.font.title"] = "Conversión de fuentes",
        ["option.font.desc"] = "La conversión de fuentes es opcional y está pensada principalmente para la compatibilidad de texto CJK en LibreCAD.",
        ["font.none"] = "No convertir",
        ["font.all"] = "Cambiar todo el texto",
        ["font.cjk"] = "Cambiar solo texto CJK",
        ["font.recommended"] = "Recomendado",
        ["font.cjkTitle"] = "¿Qué significa CJK?",
        ["font.cjkHelp"] = "CJK significa caracteres chinos, japoneses y coreanos. Usa la conversión cuando ese texto se vea dañado en LibreCAD. Si el texto ya se muestra correctamente, se recomienda No convertir.",
        ["font.cjkDetail"] = "Solo se cambia el texto que contiene caracteres chinos, japoneses o coreanos. Las letras latinas y los números conservan su estilo original cuando es posible.",
        ["font.cjkWarning"] = "En algunos dibujos, los estilos compartidos o los objetos especiales pueden impedir separar únicamente el texto CJK.",

        ["convert.button"] = "Convertir a DXF",
        ["convert.running"] = "Convirtiendo",
        ["log.empty"] = "El registro de conversión aparecerá aquí.",
        ["results.title"] = "Resultados de conversión",
        ["results.downloadZip"] = "Descargar todo en ZIP",
        ["results.review"] = "Revisar",
        ["results.verified"] = "Conversión y relectura verificadas",
        ["results.objects"] = "objetos",
        ["results.layers"] = "capas",
        ["results.text"] = "texto",
        ["results.downloadDxf"] = "Descargar DXF",

        ["footer.original"] = "Los archivos DWG originales nunca se modifican.",
        ["footer.download"] = "Los resultados solo se guardan mediante descargas del navegador.",

        ["about.title"] = "DWG2DXF Web",
        ["about.intro"] = "Una pequeña herramienta de preprocesamiento que convierte archivos DWG a DXF para revisarlos y editarlos en LibreCAD sin necesitar AutoCAD.",
        ["about.useTitle"] = "Cómo usarlo",
        ["about.step1"] = "Añade uno o más archivos DWG.",
        ["about.step2"] = "Elige la versión DXF y el modo de conversión de fuentes.",
        ["about.step3"] = "Selecciona Convertir a DXF.",
        ["about.step4"] = "Revisa el resultado de la validación por relectura y descarga el DXF.",
        ["about.step5"] = "Abre el resultado en LibreCAD y comprueba visualmente el dibujo.",
        ["about.notice"] = "Esta herramienta no es un editor CAD. No se garantiza la conversión perfecta de objetos especiales como Proxy/AEC/Civil, y la comparación del número de objetos no demuestra una equivalencia matemática.",
        ["about.platforms"] = "La versión web funciona en macOS, Windows y Linux. También hay una versión de escritorio para Windows en GitHub Releases.",
        ["about.version"] = "Web v0.3 · ACadSharp 3.6.51",

        ["fontGuide.title"] = "Instalación de fuentes en LibreCAD",
        ["fontGuide.intro"] = "El navegador no puede abrir directamente la carpeta de instalación de LibreCAD. Descarga la fuente y cópiala manualmente a la carpeta de fuentes de LibreCAD.",
        ["fontGuide.download"] = "Descargar wqy-unicode.lff",
        ["fontGuide.platform"] = "Windows / macOS",
        ["fontGuide.step1"] = "En LibreCAD, abre Application Preferences → Paths → Fonts y comprueba la carpeta de fuentes actual.",
        ["fontGuide.step2"] = "Copia wqy-unicode.lff en esa carpeta.",
        ["fontGuide.step3"] = "Cierra LibreCAD por completo.",
        ["fontGuide.step4"] = "Vuelve a iniciar LibreCAD.",
        ["fontGuide.windowsPath"] = "Ubicaciones habituales en Windows:",
        ["fontGuide.macPath"] = "En macOS, utiliza la ruta de fuentes que aparece en las preferencias de LibreCAD.",
        ["fontGuide.license"] = "Licencia de la fuente: Apache License 2.0 o GPLv3. Este proyecto la redistribuye bajo los términos de Apache License 2.0.",

        ["status.waiting"] = "En espera",
        ["status.checking"] = "Comprobando",
        ["status.ready"] = "Listo",
        ["status.error"] = "Error",
        ["status.done"] = "Completado",
        ["status.review"] = "Revisar",
        ["status.failed"] = "Falló",

        ["progress.preparing"] = "Preparando la conversión",
        ["progress.loading"] = "Cargando DWG",
        ["progress.analyzing"] = "Analizando la estructura DWG",
        ["progress.inspecting"] = "Comprobando objetos",
        ["progress.output"] = "Aplicando ajustes de salida",
        ["progress.fontCheck"] = "Comprobando ajustes de fuentes",
        ["progress.fontConvert"] = "Convirtiendo fuentes",
        ["progress.generating"] = "Generando DXF",
        ["progress.verifying"] = "Releyendo el DXF para validarlo",
        ["progress.summarizing"] = "Preparando el resultado de validación",
        ["progress.done"] = "Completado",

        ["validation.notDwg"] = "Solo se pueden añadir archivos DWG.",
        ["validation.invalidHeader"] = "La cabecera del archivo DWG no es válida.",
        ["validation.tooLarge"] = "La versión web admite archivos de hasta {0} MB cada uno.",
        ["validation.unrecognized"] = "El archivo no se reconoce como DWG.",
        ["validation.oldVersion"] = "Esta versión antigua de DWG no es compatible con el motor de conversión actual. ({0})",
        ["validation.checkFailed"] = "No se pudo comprobar el archivo: {0}",

        ["error.readDwg"] = "No se pudo leer el documento DWG.",
        ["error.emptyDxf"] = "No se pudo generar el archivo DXF.",
        ["error.verifyDxf"] = "No se pudo volver a leer el DXF generado para validarlo.",

        ["log.start"] = "Iniciando la conversión. Todo el procesamiento permanece dentro de este navegador.",
        ["log.reading"] = "Leyendo {0}...",
        ["log.analyzing"] = "Analizando la estructura DWG...",
        ["log.output2010"] = "Versión de salida: AutoCAD 2010 DXF (AC1024)",
        ["log.outputOriginal"] = "Versión de salida: mantener original ({0})",
        ["log.fontAll"] = "Fuente: wqy-unicode aplicado a todo el texto (texto {0}, atributos {1}, estilos de cota {2})",
        ["log.fontCjk"] = "Fuente: wqy-unicode aplicado solo al texto con caracteres CJK (texto {0}, atributos {1})",
        ["log.fontCjkNone"] = "Fuente: no se encontró texto CJK; se conservaron los estilos originales.",
        ["log.fontNone"] = "Fuente: sin conversión (se conservan los estilos originales)",
        ["log.generating"] = "Generando DXF...",
        ["log.generated"] = "DXF generado: {0:N0} bytes · validando mediante relectura...",
        ["log.fontVerified"] = "Validación de fuente: estilo wqy-unicode correcto (texto {0}, estilos de cota {1})",
        ["log.resultReview"] = "Conversión completada; se recomienda revisar: {0} · {1}",
        ["log.resultOk"] = "Conversión y relectura verificadas: {0} (objetos {1}, capas {2}, texto {3})",
        ["log.failure"] = "La conversión falló: {0}",
        ["log.summary"] = "Finalizado · Correctos {0} · Revisar {1} · Fallidos {2}",

        ["difference.fontStyleMissing"] = "El estilo wqy-unicode no se guardó en el DXF",
        ["difference.fontUsageZero"] = "El uso del estilo de texto wqy-unicode es 0"
    };
}
