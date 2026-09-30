# DWG2DXF v1.3.0
# Small Windows GUI for internal university administrative use.
# Conversion engine: ACadSharp 3.6.51 (MIT License)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()


# Native title-bar dark mode, taskbar identity, and asynchronous assembly loading.
Add-Type -TypeDefinition @"
using System;
using System.Drawing;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using System.Windows.Forms;

public static class HjuNative
{
    [DllImport("dwmapi.dll")]
    private static extern int DwmSetWindowAttribute(IntPtr hwnd, int dwAttribute, ref int pvAttribute, int cbAttribute);

    [DllImport("shell32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern int SetCurrentProcessExplicitAppUserModelID(string AppID);

    public static void SetDarkTitleBar(IntPtr handle, bool enabled)
    {
        if (handle == IntPtr.Zero) return;
        int value = enabled ? 1 : 0;
        try
        {
            int result = DwmSetWindowAttribute(handle, 20, ref value, sizeof(int));
            if (result != 0) DwmSetWindowAttribute(handle, 19, ref value, sizeof(int));
        }
        catch { }
    }

    public static void SetAppId(string appId)
    {
        try { SetCurrentProcessExplicitAppUserModelID(appId); } catch { }
    }
}

public static class HjuEngineLoader
{
    public static Task<string> LoadAsync(string[] paths)
    {
        return Task.Run(() =>
        {
            try
            {
                foreach (string path in paths)
                {
                    Assembly.LoadFrom(path);
                }
                return null;
            }
            catch (Exception ex)
            {
                return ex.ToString();
            }
        });
    }
}

public sealed class HjuMenuColorTable : ProfessionalColorTable
{
    private readonly bool dark;
    public HjuMenuColorTable(bool darkMode) { dark = darkMode; UseSystemColors = false; }
    private Color Bg { get { return dark ? Color.FromArgb(32,35,41) : Color.White; } }
    private Color Border { get { return dark ? Color.FromArgb(58,64,72) : Color.FromArgb(216,221,227); } }
    private Color Sel { get { return dark ? Color.FromArgb(48,53,61) : Color.FromArgb(240,244,248); } }
    public override Color ToolStripDropDownBackground { get { return Bg; } }
    public override Color ImageMarginGradientBegin { get { return Bg; } }
    public override Color ImageMarginGradientMiddle { get { return Bg; } }
    public override Color ImageMarginGradientEnd { get { return Bg; } }
    public override Color MenuBorder { get { return Border; } }
    public override Color MenuItemBorder { get { return Border; } }
    public override Color MenuItemSelected { get { return Sel; } }
    public override Color MenuItemSelectedGradientBegin { get { return Sel; } }
    public override Color MenuItemSelectedGradientEnd { get { return Sel; } }
    public override Color MenuItemPressedGradientBegin { get { return Sel; } }
    public override Color MenuItemPressedGradientMiddle { get { return Sel; } }
    public override Color MenuItemPressedGradientEnd { get { return Sel; } }
    public override Color SeparatorDark { get { return Border; } }
    public override Color SeparatorLight { get { return Border; } }
}
"@ -ReferencedAssemblies @('System.dll','System.Drawing.dll','System.Windows.Forms.dll')

[HjuNative]::SetAppId('HJU.DWG2DXF.1.3')

$script:AppDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:LibDir = Join-Path $script:AppDir 'lib'
$script:EngineReady = $false
$script:Initializing = $false
$script:Version = '1.3.0'
$script:FontResource = Join-Path $script:AppDir 'resources\wqy-unicode.lff'
$script:IconResource = Join-Path $script:AppDir 'resources\app.ico'
$script:LogoResource = Join-Path $script:AppDir 'resources\app_logo.png'
$script:SettingsDir = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'DWG2DXF'
$script:SettingsPath = Join-Path $script:SettingsDir 'settings.json'
$script:LegacySettingsPath = Join-Path (Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'HJU_DWG2DXF') 'settings.json'
$script:DarkMode = $false
$script:CustomOutputFolder = ''
$script:EngineLoadTask = $null
$script:EngineStatusKey = 'engine.preparing'
# ---------- v1.3 localization ----------
function Get-DefaultLanguage {
    $name = [Globalization.CultureInfo]::CurrentUICulture.Name.ToLowerInvariant()
    if ($name.StartsWith('ko')) { return 'ko' }
    if ($name.StartsWith('ja')) { return 'ja' }
    if ($name.StartsWith('es')) { return 'es' }
    return 'en'
}

$script:I18n = @{
    'en' = @{
        'menu.more' = 'Options'
        'menu.about' = 'About'
        'menu.language' = 'Language'
        'menu.dark' = 'Dark mode'
        'menu.save' = 'Output folder'
        'menu.saveSame' = 'Same folder as source DWG'
        'menu.saveCustom' = 'Choose another folder...'
        'menu.getFont' = 'Download LibreCAD font'
        'menu.openFont' = 'Open font folder'
        'engine.preparing' = 'Preparing conversion engine'
        'engine.ready' = 'Ready · ACadSharp 3.6.51'
        'engine.failed' = 'Engine setup failed'
        'button.add' = 'Add files'
        'button.remove' = 'Remove selected'
        'button.clear' = 'Clear all'
        'button.convert' = 'Convert to DXF'
        'label.output' = 'Output'
        'output.2010' = 'AutoCAD 2010 DXF (Recommended)'
        'output.original' = 'Keep original DWG version'
        'label.font' = 'Font conversion'
        'font.none' = 'Keep original (Recommended)'
        'font.all' = 'All text'
        'font.cjk' = 'CJK text only'
        'font.warning' = '※ CJK-only mode may miss some objects.'
        'font.help' = 'CJK = Chinese, Japanese and Korean characters. Use font conversion when CJK text is garbled in LibreCAD; otherwise Keep original is recommended.'
        'tip.fontNone' = 'Keep the original text styles. Recommended when the drawing has no CJK display problem.'
        'tip.fontAll' = 'Link all target text and dimension text styles to wqy-unicode. Use this when CJK text is garbled; it is the most reliable conversion mode.'
        'tip.fontCjk' = 'Change only text containing Chinese, Japanese, or Korean characters. Latin letters and numbers are kept in their original styles when possible.'
        'save.footerSame' = 'Save: source DWG folder  ·  Original DWG files are never modified.'
        'save.tipSame' = 'DXF files are created in the same folder as each source DWG.'
        'save.footerCustom' = 'Save: {0}  ·  Original DWG files are never modified.'
        'loading.title' = 'Loading conversion engine...'
        'loading.sub' = 'This may take a moment depending on your PC.'
        'common.ok' = 'OK'
        'common.error' = 'Error'
        'common.moreCount' = '• and {0} more'
        'invalid.message' = 'Unrecognized files were not added.`r`n`r`n{0}`r`n`r`nOnly DWG files can be added.'
        'invalid.title' = 'File not recognized'
        'validate.emptyPath' = 'The file path is empty.'
        'validate.notFound' = 'The file could not be found.'
        'validate.notDwg' = 'Only DWG files can be added.'
        'validate.badHeader' = 'The DWG file header is invalid.'
        'validate.notRecognized' = 'The file is not recognized as a DWG.'
        'validate.oldVersion' = 'This old DWG version is not supported by the current conversion engine. ({0})'
        'validate.failed' = 'The file could not be checked: {0}'
        'engine.fileMissing' = 'Conversion engine file not found: {0}`r`nRebuild the distributable EXE.'
        'dialog.outputFolder' = 'Choose the common folder for converted DXF files.'
        'dialog.fontMissing' = 'The bundled wqy-unicode.lff could not be found. Rebuild the distributable EXE.'
        'dialog.fontFilter' = 'LibreCAD LFF font (*.lff)|*.lff|All files (*.*)|*.*'
        'dialog.fontSaveTitle' = 'Save wqy-unicode.lff'
        'dialog.fontSaved' = 'Font file saved.`r`n`r`n{0}`r`n`r`nUse [Options → Open font folder], copy this file into the LibreCAD font folder, then restart LibreCAD.'
        'dialog.fontDownloadTitle' = 'LibreCAD font'
        'dialog.fontFolderTitle' = 'LibreCAD font folder'
        'dialog.fontFolderMessage' = 'The default LibreCAD font folder could not be found.`r`n`r`nCommon locations include:`r`nC:\Program Files\LibreCAD\resources\fonts`r`nC:\Program Files (x86)\LibreCAD\resources\fonts`r`n`r`nCheck [Options → Application Preferences → Paths → Fonts] in LibreCAD, or locate the resources\fonts folder inside the LibreCAD installation folder.`r`n`r`nWould you like to choose a folder manually now?'
        'dialog.fontFolderChoose' = 'Choose the LibreCAD installation folder or fonts folder.'
        'dialog.dwgFilter' = 'DWG drawings (*.dwg)|*.dwg'
        'dialog.dwgOpenTitle' = 'Select DWG files to convert'
        'log.reading' = '[{0}/{1}] {2} · reading...'
        'error.outputFolder' = 'Output folder not found: {0}'
        'error.readDwg' = 'The DWG document could not be read.'
        'log.fontAll' = '  Font: wqy-unicode applied to all text (text {0}, attributes {1}, dimension styles {2})'
        'log.fontCjk' = '  Font: wqy-unicode applied only to CJK text (text {0}, attributes {1})'
        'log.fontCjkNone' = '  Font: no CJK text found; original text styles were kept.'
        'log.fontNone' = '  Font: no conversion (original text styles kept)'
        'error.noDxf' = 'DXF file was not created.'
        'error.emptyDxf' = 'The generated DXF file is empty.'
        'error.verifyDxf' = 'The generated DXF could not be re-read for validation.'
        'diff.fontStyleMissing' = 'wqy-unicode style was not saved in the DXF'
        'diff.fontUsageZero' = 'wqy-unicode text style usage is 0'
        'log.fontVerified' = '  Font validation: wqy-unicode style OK (text {0}, dimension styles {1})'
        'log.ok' = '  ✓ Conversion/re-read validation passed: {0}  (objects {1}, layers {2}, text {3})'
        'log.review' = '  ! Conversion completed, review recommended: {0}'
        'log.changes' = '    Major object changes: {0}'
        'log.fail' = '  X Conversion failed: {0}'
        'log.summary' = 'Done: OK {0} / Review {1} / Failed {2}'
        'log.reviewAdvice' = 'Review-marked files should be compared with the source in LibreCAD, especially walls, columns, doors, and text.'
        'log.ready' = 'Ready. Drop DWG files here or select [Add files].'
        'log.fontBundled' = 'wqy-unicode.lff for CJK/Unicode text is bundled with the program.'
        'log.engineFailed' = 'Engine setup failed: {0}'
        'error.enginePrepare' = 'The conversion engine could not be prepared.`r`n`r`n{0}`r`n`r`nRebuild the distributable EXE or copy the file again.'
        'error.net48' = '.NET Framework 4.8 or later is required. Install it through Windows Update or Microsoft and run the program again.'
        'log.engineCheck' = 'Checking the ACadSharp conversion engine in the background...'
        'error.app' = 'DWG2DXF error'
        'about.title' = 'About'
        'about.version' = 'Version {0}'
    }
    'ko' = @{
        'menu.more' = '추가기능'
        'menu.about' = '프로그램 설명'
        'menu.language' = '언어 (Language)'
        'menu.dark' = '다크 모드'
        'menu.save' = '저장폴더 변경'
        'menu.saveSame' = '원본 DWG와 같은 폴더'
        'menu.saveCustom' = '다른 폴더 선택...'
        'menu.getFont' = 'LibreCAD 폰트 받기'
        'menu.openFont' = '폰트폴더 열기'
        'engine.preparing' = '변환 엔진 준비 중'
        'engine.ready' = '준비 완료 · ACadSharp 3.6.51'
        'engine.failed' = '엔진 준비 실패'
        'button.add' = '파일 추가'
        'button.remove' = '선택 삭제'
        'button.clear' = '전체 삭제'
        'button.convert' = 'DXF 변환'
        'label.output' = '출력'
        'output.2010' = 'AutoCAD 2010 DXF (권장)'
        'output.original' = '원본 DWG 버전 유지'
        'label.font' = '폰트 변환'
        'font.none' = '변환 안 함'
        'font.all' = '전체 문자 변경 (권장)'
        'font.cjk' = '한·중·일(CJK) 문자만 변경'
        'font.warning' = '※ CJK만 변경 시 일부 객체가 누락될 수 있습니다.'
        'font.help' = 'CJK = 중국어·일본어·한국어 문자. LibreCAD에서 한글·일본어 가나·한자가 깨질 때 사용하는 기능이며, 호환성이 중요하면 전체 문자 변경을 권장합니다.'
        'tip.fontNone' = '원본 문자 스타일을 그대로 유지합니다.'
        'tip.fontAll' = '모든 대상 문자와 치수 문자 스타일을 wqy-unicode로 연결합니다. 가장 안정적인 권장 방식입니다.'
        'tip.fontCjk' = '한글, 일본어 가나, 한자 등 한·중·일(CJK) 문자가 포함된 문자만 선택적으로 변경합니다. 영문·숫자는 가능한 원본 스타일을 유지합니다.'
        'save.footerSame' = '저장: 원본 DWG 폴더  ·  원본 DWG는 수정하지 않습니다.'
        'save.tipSame' = 'DXF는 각 원본 DWG와 같은 폴더에 생성됩니다.'
        'save.footerCustom' = '저장: {0}  ·  원본 DWG는 수정하지 않습니다.'
        'loading.title' = '변환 엔진을 불러오는 중...'
        'loading.sub' = 'PC 상태에 따라 잠시 시간이 걸릴 수 있습니다.'
        'common.ok' = '확인'
        'common.error' = '오류'
        'common.moreCount' = '• 외 {0}개'
        'invalid.message' = '인식할 수 없는 파일은 추가하지 않았습니다.`r`n`r`n{0}`r`n`r`nDWG 파일만 추가할 수 있습니다.'
        'invalid.title' = '파일 인식 불가'
        'validate.emptyPath' = '파일 경로가 비어 있습니다.'
        'validate.notFound' = '파일을 찾을 수 없습니다.'
        'validate.notDwg' = 'DWG 파일만 추가할 수 있습니다.'
        'validate.badHeader' = 'DWG 파일 헤더가 올바르지 않습니다.'
        'validate.notRecognized' = 'DWG 형식으로 인식할 수 없습니다.'
        'validate.oldVersion' = '현재 변환 엔진에서 지원하지 않는 오래된 DWG 버전입니다. ({0})'
        'validate.failed' = '파일을 확인할 수 없습니다: {0}'
        'engine.fileMissing' = '변환 엔진 파일을 찾지 못했습니다: {0}`r`n배포용 EXE를 다시 빌드해 주세요.'
        'dialog.outputFolder' = 'DXF 파일을 저장할 공통 폴더를 선택하세요.'
        'dialog.fontMissing' = '프로그램에 포함된 wqy-unicode.lff 파일을 찾지 못했습니다. 배포용 EXE를 다시 빌드해 주세요.'
        'dialog.fontFilter' = 'LibreCAD LFF 글꼴 (*.lff)|*.lff|모든 파일 (*.*)|*.*'
        'dialog.fontSaveTitle' = 'wqy-unicode.lff 저장'
        'dialog.fontSaved' = '글꼴 파일을 저장했습니다.`r`n`r`n{0}`r`n`r`n[추가기능 → 폰트폴더 열기]로 LibreCAD 폰트 폴더를 연 뒤 이 파일을 복사하고 LibreCAD를 다시 실행하세요.'
        'dialog.fontDownloadTitle' = 'LibreCAD 폰트 받기'
        'dialog.fontFolderTitle' = 'LibreCAD 폰트 폴더'
        'dialog.fontFolderMessage' = 'LibreCAD의 기본 폰트 폴더를 찾지 못했습니다.`r`n`r`n일반적으로 아래 위치 중 하나입니다.`r`nC:\Program Files\LibreCAD\resources\fonts`r`nC:\Program Files (x86)\LibreCAD\resources\fonts`r`n`r`nLibreCAD에서 [옵션 → 응용프로그램 설정 → 경로 → 글꼴]을 확인하거나, LibreCAD 설치 폴더 안의 resources\fonts 폴더를 직접 찾아주세요.`r`n`r`n지금 직접 폴더를 찾아 열까요?'
        'dialog.fontFolderChoose' = 'LibreCAD 설치 폴더 또는 fonts 폴더를 선택하세요.'
        'dialog.dwgFilter' = 'DWG 도면 (*.dwg)|*.dwg'
        'dialog.dwgOpenTitle' = '변환할 DWG 파일 선택'
        'log.reading' = '[{0}/{1}] {2} 읽는 중...'
        'error.outputFolder' = '저장 폴더를 찾을 수 없습니다: {0}'
        'error.readDwg' = 'DWG 문서를 읽지 못했습니다.'
        'log.fontAll' = '  글꼴: 전체 문자 wqy-unicode 적용 (문자 {0}, 속성 {1}, 치수스타일 {2})'
        'log.fontCjk' = '  글꼴: CJK 포함 문자만 wqy-unicode 적용 (문자 {0}, 속성 {1})'
        'log.fontCjkNone' = '  글꼴: CJK 문자를 찾지 못해 원본 문자 스타일을 유지했습니다.'
        'log.fontNone' = '  글꼴: 변환하지 않음 (원본 문자 스타일 유지)'
        'error.noDxf' = 'DXF 파일이 생성되지 않았습니다.'
        'error.emptyDxf' = '생성된 DXF 파일의 크기가 0입니다.'
        'error.verifyDxf' = '생성된 DXF를 다시 읽어 검증하지 못했습니다.'
        'diff.fontStyleMissing' = 'wqy-unicode 스타일이 DXF에 저장되지 않음'
        'diff.fontUsageZero' = 'wqy-unicode 문자 스타일 적용 0건'
        'log.fontVerified' = '  글꼴 재검증: wqy-unicode 스타일 정상 (문자 {0}, 치수스타일 {1})'
        'log.ok' = '  ✓ 변환/재읽기 검증 통과: {0}  (객체 {1}, 레이어 {2}, 문자 {3})'
        'log.review' = '  ! 변환 완료, 확인 필요: {0}'
        'log.changes' = '    주요 객체 변화: {0}'
        'log.fail' = '  X 변환 실패: {0}'
        'log.summary' = '완료: 정상 {0} / 확인필요 {1} / 실패 {2}'
        'log.reviewAdvice' = '확인필요 파일은 LibreCAD에서 벽/기둥/문/문자 위치를 원본과 대조해 주세요.'
        'log.ready' = '준비 완료. DWG 파일을 끌어놓거나 [파일 추가]를 누르세요.'
        'log.fontBundled' = 'CJK/Unicode용 wqy-unicode.lff가 프로그램에 포함되어 있습니다.'
        'log.engineFailed' = '엔진 준비 실패: {0}'
        'error.enginePrepare' = '변환 엔진을 준비하지 못했습니다.`r`n`r`n{0}`r`n`r`n배포용 EXE를 다시 빌드하거나 파일을 다시 복사해 주세요.'
        'error.net48' = '.NET Framework 4.8 이상이 필요합니다. Windows Update 또는 Microsoft 공식 설치본으로 무료 설치 후 다시 실행해 주세요.'
        'log.engineCheck' = 'ACadSharp 변환 엔진을 백그라운드에서 확인하는 중...'
        'error.app' = 'DWG2DXF 오류'
        'about.title' = '프로그램 설명'
        'about.version' = '버전 {0}'
    }
    'ja' = @{
        'menu.more' = 'その他'
        'menu.about' = 'このツールについて'
        'menu.language' = '言語 (Language)'
        'menu.dark' = 'ダークモード'
        'menu.save' = '保存先'
        'menu.saveSame' = '元のDWGと同じフォルダ'
        'menu.saveCustom' = '別のフォルダを選択...'
        'menu.getFont' = 'LibreCADフォントを保存'
        'menu.openFont' = 'フォントフォルダを開く'
        'engine.preparing' = '変換エンジン準備中'
        'engine.ready' = '準備完了 · ACadSharp 3.6.51'
        'engine.failed' = 'エンジン準備失敗'
        'button.add' = 'ファイル追加'
        'button.remove' = '選択削除'
        'button.clear' = 'すべて削除'
        'button.convert' = 'DXF変換'
        'label.output' = '出力'
        'output.2010' = 'AutoCAD 2010 DXF（推奨）'
        'output.original' = '元のDWGバージョンを維持'
        'label.font' = 'フォント変換'
        'font.none' = '変換なし'
        'font.all' = '全文字変更（推奨）'
        'font.cjk' = 'CJK文字のみ'
        'font.warning' = '※ CJKのみの変換は一部オブジェクトを検出できない場合があります。'
        'font.help' = 'CJK = 中国語・日本語・韓国語の文字です。LibreCADでハングル・かな・漢字などが文字化けする場合に使用し、互換性を優先する場合は全文字変更を推奨します。'
        'tip.fontNone' = '元の文字スタイルを維持します。'
        'tip.fontAll' = '対象の文字と寸法文字スタイルをすべて wqy-unicode に接続します。最も安定した推奨方法です。'
        'tip.fontCjk' = 'ハングル、かな、漢字などCJK文字を含むテキストのみ変更し、英数字は可能な限り元のスタイルを維持します。'
        'save.footerSame' = '保存: 元のDWGフォルダ  ·  元のDWGは変更しません。'
        'save.tipSame' = 'DXFは各元DWGと同じフォルダに作成されます。'
        'save.footerCustom' = '保存: {0}  ·  元のDWGは変更しません。'
        'loading.title' = '変換エンジンを読み込み中...'
        'loading.sub' = 'PCの状態により少し時間がかかる場合があります。'
        'common.ok' = 'OK'
        'common.error' = 'エラー'
        'common.moreCount' = '• 他 {0} 件'
        'invalid.message' = '認識できないファイルは追加しませんでした。`r`n`r`n{0}`r`n`r`nDWGファイルのみ追加できます。'
        'invalid.title' = 'ファイルを認識できません'
        'validate.emptyPath' = 'ファイルパスが空です。'
        'validate.notFound' = 'ファイルが見つかりません。'
        'validate.notDwg' = 'DWGファイルのみ追加できます。'
        'validate.badHeader' = 'DWGファイルのヘッダーが正しくありません。'
        'validate.notRecognized' = 'DWG形式として認識できません。'
        'validate.oldVersion' = '現在の変換エンジンでは対応していない古いDWGバージョンです。({0})'
        'validate.failed' = 'ファイルを確認できません: {0}'
        'engine.fileMissing' = '変換エンジンのファイルが見つかりません: {0}`r`n配布用EXEを再ビルドしてください。'
        'dialog.outputFolder' = '変換したDXFを保存する共通フォルダを選択してください。'
        'dialog.fontMissing' = '内蔵の wqy-unicode.lff が見つかりません。配布用EXEを再ビルドしてください。'
        'dialog.fontFilter' = 'LibreCAD LFFフォント (*.lff)|*.lff|すべてのファイル (*.*)|*.*'
        'dialog.fontSaveTitle' = 'wqy-unicode.lff を保存'
        'dialog.fontSaved' = 'フォントファイルを保存しました。`r`n`r`n{0}`r`n`r`n[その他 → フォントフォルダを開く] でLibreCADのフォントフォルダを開き、このファイルをコピーしてLibreCADを再起動してください。'
        'dialog.fontDownloadTitle' = 'LibreCADフォント'
        'dialog.fontFolderTitle' = 'LibreCADフォントフォルダ'
        'dialog.fontFolderMessage' = 'LibreCADの標準フォントフォルダが見つかりませんでした。`r`n`r`n一般的な場所:`r`nC:\Program Files\LibreCAD\resources\fonts`r`nC:\Program Files (x86)\LibreCAD\resources\fonts`r`n`r`nLibreCADの [オプション → アプリケーション設定 → パス → フォント] を確認するか、LibreCADのインストールフォルダ内の resources\fonts を探してください。`r`n`r`n今すぐ手動でフォルダを選択しますか?'
        'dialog.fontFolderChoose' = 'LibreCADのインストールフォルダまたはfontsフォルダを選択してください。'
        'dialog.dwgFilter' = 'DWG図面 (*.dwg)|*.dwg'
        'dialog.dwgOpenTitle' = '変換するDWGファイルを選択'
        'log.reading' = '[{0}/{1}] {2} を読み込み中...'
        'error.outputFolder' = '保存先フォルダが見つかりません: {0}'
        'error.readDwg' = 'DWGドキュメントを読み込めませんでした。'
        'log.fontAll' = '  フォント: 全文字に wqy-unicode を適用（文字 {0}、属性 {1}、寸法スタイル {2}）'
        'log.fontCjk' = '  フォント: CJK文字を含むテキストのみに wqy-unicode を適用（文字 {0}、属性 {1}）'
        'log.fontCjkNone' = '  フォント: CJK文字が見つからなかったため、元の文字スタイルを維持しました。'
        'log.fontNone' = '  フォント: 変換なし（元の文字スタイルを維持）'
        'error.noDxf' = 'DXFファイルが作成されませんでした。'
        'error.emptyDxf' = '生成されたDXFファイルのサイズが0です。'
        'error.verifyDxf' = '生成したDXFを再読み込みして検証できませんでした。'
        'diff.fontStyleMissing' = 'wqy-unicode スタイルがDXFに保存されていません'
        'diff.fontUsageZero' = 'wqy-unicode 文字スタイルの適用件数が0です'
        'log.fontVerified' = '  フォント再検証: wqy-unicode スタイル正常（文字 {0}、寸法スタイル {1}）'
        'log.ok' = '  ✓ 変換・再読み込み検証済み: {0}  (オブジェクト {1}、レイヤー {2}、文字 {3})'
        'log.review' = '  ! 変換完了・要確認: {0}'
        'log.changes' = '    主なオブジェクト変化: {0}'
        'log.fail' = '  X 変換失敗: {0}'
        'log.summary' = '完了: 正常 {0} / 要確認 {1} / 失敗 {2}'
        'log.reviewAdvice' = '要確認のファイルはLibreCADで壁、柱、ドア、文字位置を元データと比較してください。'
        'log.ready' = '準備完了。DWGファイルをドロップするか [ファイル追加] を選択してください。'
        'log.fontBundled' = 'CJK/Unicode用 wqy-unicode.lff がプログラムに含まれています。'
        'log.engineFailed' = 'エンジン準備失敗: {0}'
        'error.enginePrepare' = '変換エンジンを準備できませんでした。`r`n`r`n{0}`r`n`r`n配布用EXEを再ビルドするか、ファイルを再コピーしてください。'
        'error.net48' = '.NET Framework 4.8 以降が必要です。Windows UpdateまたはMicrosoft公式インストーラーで導入してから再実行してください。'
        'log.engineCheck' = 'ACadSharp変換エンジンをバックグラウンドで確認中...'
        'error.app' = 'DWG2DXF エラー'
        'about.title' = 'このツールについて'
        'about.version' = 'バージョン {0}'
    }
    'es' = @{
        'menu.more' = 'Opciones'
        'menu.about' = 'Acerca del programa'
        'menu.language' = 'Idioma (Language)'
        'menu.dark' = 'Modo oscuro'
        'menu.save' = 'Carpeta de salida'
        'menu.saveSame' = 'Misma carpeta que el DWG'
        'menu.saveCustom' = 'Elegir otra carpeta...'
        'menu.getFont' = 'Guardar fuente de LibreCAD'
        'menu.openFont' = 'Abrir carpeta de fuentes'
        'engine.preparing' = 'Preparando motor de conversión'
        'engine.ready' = 'Listo · ACadSharp 3.6.51'
        'engine.failed' = 'Error al preparar el motor'
        'button.add' = 'Añadir'
        'button.remove' = 'Quitar'
        'button.clear' = 'Limpiar'
        'button.convert' = 'Convertir a DXF'
        'label.output' = 'Salida'
        'output.2010' = 'AutoCAD 2010 DXF (Recomendado)'
        'output.original' = 'Mantener versión DWG original'
        'label.font' = 'Fuentes'
        'font.none' = 'Sin cambios (Recomendado)'
        'font.all' = 'Todo texto'
        'font.cjk' = 'Solo texto CJK'
        'font.warning' = '※ El modo solo CJK puede omitir algunos objetos.'
        'font.help' = 'CJK = caracteres chinos, japoneses y coreanos. Usa la conversión si ese texto se ve dañado en LibreCAD; si se ve bien, se recomienda Sin cambios.'
        'tip.fontNone' = 'Conserva los estilos originales. Recomendado cuando el dibujo no tiene problemas de visualización CJK.'
        'tip.fontAll' = 'Vincula el texto y los estilos de cota a wqy-unicode. Úsalo cuando el texto CJK se vea dañado; es el modo de conversión más fiable.'
        'tip.fontCjk' = 'Cambia solo texto con caracteres chinos, japoneses o coreanos. Las letras latinas y los números conservan su estilo original cuando es posible.'
        'save.footerSame' = 'Guardar: carpeta del DWG  ·  El DWG original no se modifica.'
        'save.tipSame' = 'Los DXF se crean en la misma carpeta que cada DWG original.'
        'save.footerCustom' = 'Guardar: {0}  ·  El DWG original no se modifica.'
        'loading.title' = 'Cargando motor de conversión...'
        'loading.sub' = 'Puede tardar un poco según el estado del PC.'
        'common.ok' = 'Aceptar'
        'common.error' = 'Error'
        'common.moreCount' = '• y {0} más'
        'invalid.message' = 'Los archivos no reconocidos no se añadieron.`r`n`r`n{0}`r`n`r`nSolo se pueden añadir archivos DWG.'
        'invalid.title' = 'Archivo no reconocido'
        'validate.emptyPath' = 'La ruta del archivo está vacía.'
        'validate.notFound' = 'No se encontró el archivo.'
        'validate.notDwg' = 'Solo se pueden añadir archivos DWG.'
        'validate.badHeader' = 'La cabecera del archivo DWG no es válida.'
        'validate.notRecognized' = 'El archivo no se reconoce como DWG.'
        'validate.oldVersion' = 'Esta versión antigua de DWG no es compatible con el motor actual. ({0})'
        'validate.failed' = 'No se pudo comprobar el archivo: {0}'
        'engine.fileMissing' = 'No se encontró el archivo del motor de conversión: {0}`r`nVuelve a compilar el EXE de distribución.'
        'dialog.outputFolder' = 'Elige la carpeta común para guardar los DXF convertidos.'
        'dialog.fontMissing' = 'No se encontró wqy-unicode.lff incluido en el programa. Vuelve a compilar el EXE de distribución.'
        'dialog.fontFilter' = 'Fuente LFF de LibreCAD (*.lff)|*.lff|Todos los archivos (*.*)|*.*'
        'dialog.fontSaveTitle' = 'Guardar wqy-unicode.lff'
        'dialog.fontSaved' = 'Archivo de fuente guardado.`r`n`r`n{0}`r`n`r`nUsa [Opciones → Abrir carpeta de fuentes], copia este archivo en la carpeta de fuentes de LibreCAD y reinicia LibreCAD.'
        'dialog.fontDownloadTitle' = 'Fuente de LibreCAD'
        'dialog.fontFolderTitle' = 'Carpeta de fuentes de LibreCAD'
        'dialog.fontFolderMessage' = 'No se encontró la carpeta de fuentes predeterminada de LibreCAD.`r`n`r`nUbicaciones habituales:`r`nC:\Program Files\LibreCAD\resources\fonts`r`nC:\Program Files (x86)\LibreCAD\resources\fonts`r`n`r`nRevisa [Opciones → Preferencias de la aplicación → Rutas → Fuentes] en LibreCAD o busca resources\fonts dentro de la carpeta de instalación.`r`n`r`n¿Quieres elegir una carpeta manualmente ahora?'
        'dialog.fontFolderChoose' = 'Elige la carpeta de instalación de LibreCAD o la carpeta fonts.'
        'dialog.dwgFilter' = 'Dibujos DWG (*.dwg)|*.dwg'
        'dialog.dwgOpenTitle' = 'Seleccionar archivos DWG para convertir'
        'log.reading' = '[{0}/{1}] Leyendo {2}...'
        'error.outputFolder' = 'No se encontró la carpeta de salida: {0}'
        'error.readDwg' = 'No se pudo leer el documento DWG.'
        'log.fontAll' = '  Fuente: wqy-unicode aplicado a todo el texto (texto {0}, atributos {1}, estilos de cota {2})'
        'log.fontCjk' = '  Fuente: wqy-unicode aplicado solo al texto CJK (texto {0}, atributos {1})'
        'log.fontCjkNone' = '  Fuente: no se encontró texto CJK; se conservaron los estilos originales.'
        'log.fontNone' = '  Fuente: sin conversión (se conservan los estilos originales)'
        'error.noDxf' = 'No se creó el archivo DXF.'
        'error.emptyDxf' = 'El archivo DXF generado está vacío.'
        'error.verifyDxf' = 'No se pudo volver a leer el DXF generado para validarlo.'
        'diff.fontStyleMissing' = 'El estilo wqy-unicode no se guardó en el DXF'
        'diff.fontUsageZero' = 'El uso del estilo de texto wqy-unicode es 0'
        'log.fontVerified' = '  Validación de fuente: estilo wqy-unicode correcto (texto {0}, estilos de cota {1})'
        'log.ok' = '  ✓ Conversión y relectura verificadas: {0}  (objetos {1}, capas {2}, texto {3})'
        'log.review' = '  ! Conversión completada, revisar: {0}'
        'log.changes' = '    Cambios principales de objetos: {0}'
        'log.fail' = '  X Falló la conversión: {0}'
        'log.summary' = 'Finalizado: Correctos {0} / Revisar {1} / Fallidos {2}'
        'log.reviewAdvice' = 'Compara los archivos marcados para revisión con el original en LibreCAD, especialmente paredes, columnas, puertas y texto.'
        'log.ready' = 'Listo. Arrastra archivos DWG o selecciona [Añadir].'
        'log.fontBundled' = 'wqy-unicode.lff para texto CJK/Unicode está incluido en el programa.'
        'log.engineFailed' = 'Error al preparar el motor: {0}'
        'error.enginePrepare' = 'No se pudo preparar el motor de conversión.`r`n`r`n{0}`r`n`r`nVuelve a compilar el EXE de distribución o copia de nuevo el archivo.'
        'error.net48' = 'Se requiere .NET Framework 4.8 o posterior. Instálalo mediante Windows Update o Microsoft y vuelve a ejecutar el programa.'
        'log.engineCheck' = 'Comprobando el motor de conversión ACadSharp en segundo plano...'
        'error.app' = 'Error de DWG2DXF'
        'about.title' = 'Acerca del programa'
        'about.version' = 'Versión {0}'
    }
}

$script:Language = Get-DefaultLanguage

function T {
    param([Parameter(Mandatory=$true)][string]$Key, [object[]]$Args = @())
    $lang = $script:Language
    if (-not $script:I18n.ContainsKey($lang)) { $lang = 'en' }
    $value = $script:I18n[$lang][$Key]
    if ([string]::IsNullOrEmpty([string]$value)) { $value = $script:I18n['en'][$Key] }
    if ([string]::IsNullOrEmpty([string]$value)) { return $Key }
    $value = ([string]$value).Replace('`r`n', "`r`n").Replace('`n', "`n")
    if ($null -ne $Args -and $Args.Count -gt 0) { return [string]::Format([string]$value, $Args) }
    return [string]$value
}

function Get-UiFontName {
    switch ($script:Language) { 'ko' { return 'Malgun Gothic' } 'ja' { return 'Yu Gothic UI' } default { return 'Segoe UI' } }
}


if (-not (Test-Path $script:LibDir)) {
    New-Item -ItemType Directory -Path $script:LibDir | Out-Null
}

function Write-StartupError([string]$Message) {
    try {
        $path = Join-Path $script:AppDir 'startup_error.txt'
        "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $Message" | Out-File -FilePath $path -Encoding UTF8
    } catch { }
}

function Test-NetFramework48 {
    try {
        $release = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -Name Release -ErrorAction Stop).Release
        return ([int]$release -ge 528040)
    } catch {
        return $false
    }
}

function Get-PackageDll {
    param(
        [Parameter(Mandatory=$true)][string]$Id,
        [Parameter(Mandatory=$true)][string]$Version,
        [Parameter(Mandatory=$true)][string]$RelativeDll,
        [Parameter(Mandatory=$true)][string]$DllName
    )

    $target = Join-Path $script:LibDir $DllName
    if (Test-Path $target) { return $target }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $tmpBase = Join-Path ([IO.Path]::GetTempPath()) ("DWG2DXF_" + [guid]::NewGuid().ToString('N'))
    $zipPath = $tmpBase + '.zip'
    $extractPath = $tmpBase + '_x'
    $url = "https://www.nuget.org/api/v2/package/$Id/$Version"

    try {
        Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $zipPath -ErrorAction Stop
        Expand-Archive -LiteralPath $zipPath -DestinationPath $extractPath -Force

        $source = Join-Path $extractPath $RelativeDll
        if (-not (Test-Path $source)) {
            $candidate = Get-ChildItem -LiteralPath $extractPath -Recurse -File -Filter $DllName -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -match '[\\/]lib[\\/]' } |
                Select-Object -First 1
            if ($null -eq $candidate) {
                throw "NuGet package $Id $Version does not contain $DllName."
            }
            $source = $candidate.FullName
        }

        Copy-Item -LiteralPath $source -Destination $target -Force
        return $target
    }
    finally {
        Remove-Item -LiteralPath $zipPath -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $extractPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Load-EngineAssemblies {
    $packages = @(
        @{ Id='System.Runtime.CompilerServices.Unsafe'; Version='6.1.2'; Relative='lib\net462\System.Runtime.CompilerServices.Unsafe.dll'; Dll='System.Runtime.CompilerServices.Unsafe.dll' },
        @{ Id='System.Buffers'; Version='4.6.1'; Relative='lib\net462\System.Buffers.dll'; Dll='System.Buffers.dll' },
        @{ Id='System.Numerics.Vectors'; Version='4.6.1'; Relative='lib\net462\System.Numerics.Vectors.dll'; Dll='System.Numerics.Vectors.dll' },
        @{ Id='System.Memory'; Version='4.6.3'; Relative='lib\net462\System.Memory.dll'; Dll='System.Memory.dll' },
        @{ Id='ACadSharp'; Version='3.6.51'; Relative='lib\net48\ACadSharp.dll'; Dll='ACadSharp.dll' }
    )

    foreach ($p in $packages) {
        $dll = Get-PackageDll -Id $p.Id -Version $p.Version -RelativeDll $p.Relative -DllName $p.Dll
        try {
            [Reflection.Assembly]::LoadFrom($dll) | Out-Null
        } catch {
            if ($_.Exception.Message -notmatch 'already loaded') { throw }
        }
    }
}

function Get-DocStats($doc) {
    $stats = [ordered]@{
        Total = 0
        Line = 0
        Polyline = 0
        Arc = 0
        Circle = 0
        Insert = 0
        Text = 0
        Dimension = 0
        Hatch = 0
        Other = 0
        Layers = 0
        Blocks = 0
    }

    try { $stats.Layers = [int]$doc.Layers.Count } catch { }
    try { $stats.Blocks = [int]$doc.BlockRecords.Count } catch { }

    $usedBlockRecords = $false
    try {
        foreach ($br in $doc.BlockRecords) {
            $usedBlockRecords = $true
            try {
                foreach ($entity in $br.Entities) {
                    if ($null -eq $entity) { continue }
                    $stats.Total++
                    $n = $entity.GetType().Name
                    switch -Regex ($n) {
                        '^Line$' { $stats.Line++; break }
                        'Polyline' { $stats.Polyline++; break }
                        '^Arc$' { $stats.Arc++; break }
                        '^Circle$' { $stats.Circle++; break }
                        '^Insert$' { $stats.Insert++; break }
                        '^(TextEntity|MText|AttributeEntity|AttributeDefinition)$' { $stats.Text++; break }
                        '^Dimension' { $stats.Dimension++; break }
                        '^Hatch$' { $stats.Hatch++; break }
                        default { $stats.Other++ }
                    }
                }
            } catch { }
        }
    } catch { $usedBlockRecords = $false }

    if (-not $usedBlockRecords) {
        try {
            foreach ($entity in $doc.Entities) {
                if ($null -eq $entity) { continue }
                $stats.Total++
                $n = $entity.GetType().Name
                switch -Regex ($n) {
                    '^Line$' { $stats.Line++; break }
                    'Polyline' { $stats.Polyline++; break }
                    '^Arc$' { $stats.Arc++; break }
                    '^Circle$' { $stats.Circle++; break }
                    '^Insert$' { $stats.Insert++; break }
                    '^(TextEntity|MText|AttributeEntity|AttributeDefinition)$' { $stats.Text++; break }
                    '^Dimension' { $stats.Dimension++; break }
                    '^Hatch$' { $stats.Hatch++; break }
                    default { $stats.Other++ }
                }
            }
        } catch { }
    }

    return [pscustomobject]$stats
}

function Compare-Stats($before, $after) {
    $diffs = New-Object System.Collections.Generic.List[string]
    $fields = @('Total','Line','Polyline','Arc','Circle','Insert','Text')
    foreach ($f in $fields) {
        $a = [int]$before.$f
        $b = [int]$after.$f
        if ($a -ne $b) {
            $diffs.Add("$f $a -> $b")
        }
    }
    return $diffs
}

function Get-OutputPath([string]$InputPath, [string]$OutputFolder) {
    $base = [IO.Path]::GetFileNameWithoutExtension($InputPath)
    $candidate = Join-Path $OutputFolder ($base + '.dxf')
    if (-not (Test-Path $candidate)) { return $candidate }

    $candidate = Join-Path $OutputFolder ($base + '_converted.dxf')
    if (-not (Test-Path $candidate)) { return $candidate }

    $i = 2
    while ($true) {
        $candidate = Join-Path $OutputFolder ("${base}_converted_${i}.dxf")
        if (-not (Test-Path $candidate)) { return $candidate }
        $i++
    }
}


function Get-WqyUnicodeStyle($doc) {
    $styleName = 'wqy-unicode'
    $style = $null

    try {
        if ($doc.TextStyles.Contains($styleName)) {
            $style = $doc.TextStyles[$styleName]
        }
    } catch { }

    if ($null -eq $style) {
        $newStyle = [ACadSharp.Tables.TextStyle]::new($styleName)
        $newStyle.Filename = 'wqy-unicode.lff'
        $newStyle.BigFontFilename = ''
        $style = $doc.TextStyles.TryAdd($newStyle)
    }

    # LibreCAD에서 스타일 이름과 LFF 파일명이 일치하도록 명시합니다.
    $style.Filename = 'wqy-unicode.lff'
    $style.BigFontFilename = ''
    return $style
}

function Test-ContainsCjk([string]$Text) {
    if ([string]::IsNullOrEmpty($Text)) { return $false }
    # Hangul, Hiragana, Katakana, common Han/CJK ideographs, and related BMP ranges.
    return [Text.RegularExpressions.Regex]::IsMatch($Text, '[\u1100-\u11FF\u3130-\u318F\uA960-\uA97F\uAC00-\uD7AF\uD7B0-\uD7FF\u3040-\u309F\u30A0-\u30FF\u31F0-\u31FF\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF\uFF65-\uFF9F]')
}

function Get-CadTextValue($entity) {
    if ($null -eq $entity) { return '' }
    try {
        $valueProp = $entity.PSObject.Properties['Value']
        if ($null -ne $valueProp -and $null -ne $entity.Value) { return [string]$entity.Value }
    } catch { }
    return ''
}

function Test-EntityContainsCjk($entity) {
    if ($null -eq $entity) { return $false }
    if (Test-ContainsCjk (Get-CadTextValue $entity)) { return $true }
    try {
        if ($null -ne $entity.MText -and (Test-ContainsCjk (Get-CadTextValue $entity.MText))) { return $true }
    } catch { }
    return $false
}

function Set-WqyUnicodeStyle($doc, [string]$Mode = 'All') {
    $cjkOnly = ($Mode -eq 'CjkOnly')
    $wqy = $null
    $textCount = 0
    $attributeCount = 0
    $dimensionStyleCount = 0
    $usedBlockRecords = $false

    try {
        foreach ($br in $doc.BlockRecords) {
            $usedBlockRecords = $true
            foreach ($entity in $br.Entities) {
                if ($null -eq $entity) { continue }

                # TEXT / MTEXT / ATTRIB / ATTDEF 등 TextStyle을 직접 가지는 객체
                try {
                    $styleProp = $entity.PSObject.Properties['Style']
                    $shouldApply = (-not $cjkOnly) -or (Test-EntityContainsCjk $entity)
                    if ($shouldApply -and $null -ne $styleProp -and $entity.Style -is [ACadSharp.Tables.TextStyle]) {
                        if ($null -eq $wqy) { $wqy = Get-WqyUnicodeStyle $doc }
                        $entity.Style = $wqy
                        $textCount++
                    }
                } catch { }

                # INSERT 내부 속성 문자(ATTRIB)
                try {
                    $attrsProp = $entity.PSObject.Properties['Attributes']
                    if ($null -ne $attrsProp -and $null -ne $entity.Attributes) {
                        foreach ($attr in $entity.Attributes) {
                            if ($null -eq $attr) { continue }
                            $attrHasCjk = Test-EntityContainsCjk $attr
                            if (((-not $cjkOnly) -or $attrHasCjk) -and $attr.Style -is [ACadSharp.Tables.TextStyle]) {
                                if ($null -eq $wqy) { $wqy = Get-WqyUnicodeStyle $doc }
                                $attr.Style = $wqy
                                $attributeCount++
                            }
                            try {
                                if ($null -ne $attr.MText -and ((-not $cjkOnly) -or (Test-ContainsCjk (Get-CadTextValue $attr.MText))) -and $attr.MText.Style -is [ACadSharp.Tables.TextStyle]) {
                                    if ($null -eq $wqy) { $wqy = Get-WqyUnicodeStyle $doc }
                                    $attr.MText.Style = $wqy
                                    $attributeCount++
                                }
                            } catch { }
                        }
                    }
                } catch { }
            }
        }
    } catch {
        $usedBlockRecords = $false
    }

    # 일부 문서에서 BlockRecords 열거가 불가능할 경우 ModelSpace 엔티티를 직접 처리
    if (-not $usedBlockRecords) {
        try {
            foreach ($entity in $doc.Entities) {
                if ($null -eq $entity) { continue }
                try {
                    $shouldApply = (-not $cjkOnly) -or (Test-EntityContainsCjk $entity)
                    if ($shouldApply -and $entity.Style -is [ACadSharp.Tables.TextStyle]) {
                        if ($null -eq $wqy) { $wqy = Get-WqyUnicodeStyle $doc }
                        $entity.Style = $wqy
                        $textCount++
                    }
                } catch { }
            }
        } catch { }
    }

    # 전체 변경 모드에서는 치수 문자 스타일도 wqy-unicode에 연결합니다.
    # CJK 포함 문자만 변경 모드에서는 공유 DimensionStyle을 바꾸면 숫자/영문 치수까지 영향을
    # 받을 수 있으므로 의도적으로 건드리지 않습니다. 이 제한은 UI/설명에 경고합니다.
    if (-not $cjkOnly) {
        try {
            foreach ($dimStyle in $doc.DimensionStyles) {
                if ($null -eq $dimStyle) { continue }
                if ($null -eq $wqy) { $wqy = Get-WqyUnicodeStyle $doc }
                $dimStyle.Style = $wqy
                $dimensionStyleCount++
            }
        } catch { }
    }

    return [pscustomobject]@{
        TextEntities = $textCount
        Attributes = $attributeCount
        DimensionStyles = $dimensionStyleCount
        TotalApplied = ($textCount + $attributeCount + $dimensionStyleCount)
        Mode = $Mode
    }
}

function Get-WqyUnicodeUsage($doc) {
    $styleExists = $false
    $textCount = 0
    $dimensionStyleCount = 0

    try { $styleExists = $doc.TextStyles.Contains('wqy-unicode') } catch { }

    try {
        foreach ($br in $doc.BlockRecords) {
            foreach ($entity in $br.Entities) {
                if ($null -eq $entity) { continue }
                try {
                    if ($entity.Style -is [ACadSharp.Tables.TextStyle] -and $entity.Style.Name -eq 'wqy-unicode') {
                        $textCount++
                    }
                } catch { }
                try {
                    if ($null -ne $entity.Attributes) {
                        foreach ($attr in $entity.Attributes) {
                            if ($null -ne $attr -and $attr.Style -is [ACadSharp.Tables.TextStyle] -and $attr.Style.Name -eq 'wqy-unicode') {
                                $textCount++
                            }
                        }
                    }
                } catch { }
            }
        }
    } catch { }

    try {
        foreach ($dimStyle in $doc.DimensionStyles) {
            if ($null -ne $dimStyle.Style -and $dimStyle.Style.Name -eq 'wqy-unicode') {
                $dimensionStyleCount++
            }
        }
    } catch { }

    return [pscustomobject]@{
        StyleExists = $styleExists
        TextEntities = $textCount
        DimensionStyles = $dimensionStyleCount
    }
}

function Get-LibreCadFontFolder {
    $candidates = New-Object System.Collections.Generic.List[string]

    if (-not [string]::IsNullOrWhiteSpace($env:ProgramFiles)) {
        $candidates.Add((Join-Path $env:ProgramFiles 'LibreCAD\resources\fonts'))
        $candidates.Add((Join-Path $env:ProgramFiles 'LibreCAD\share\librecad\fonts'))
    }
    $pf86 = ${env:ProgramFiles(x86)}
    if (-not [string]::IsNullOrWhiteSpace($pf86)) {
        $candidates.Add((Join-Path $pf86 'LibreCAD\resources\fonts'))
        $candidates.Add((Join-Path $pf86 'LibreCAD\share\librecad\fonts'))
    }

    # 설치 프로그램이 InstallLocation을 등록한 경우도 확인합니다.
    $uninstallRoots = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($root in $uninstallRoots) {
        try {
            $apps = Get-ItemProperty $root -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like 'LibreCAD*' }
            foreach ($app in $apps) {
                if ([string]::IsNullOrWhiteSpace($app.InstallLocation)) { continue }
                $candidates.Add((Join-Path $app.InstallLocation 'resources\fonts'))
                $candidates.Add((Join-Path $app.InstallLocation 'share\librecad\fonts'))
            }
        } catch { }
    }

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Container) {
            return $candidate
        }
    }
    return $null
}

# ---------- v1.3 settings / UX helpers ----------
function Load-AppSettings {
    try {
        $sourcePath = $script:SettingsPath
        if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf) -and (Test-Path -LiteralPath $script:LegacySettingsPath -PathType Leaf)) {
            $sourcePath = $script:LegacySettingsPath
        }
        if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) { return }
        $obj = Get-Content -LiteralPath $sourcePath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($null -ne $obj.DarkMode) { $script:DarkMode = [bool]$obj.DarkMode }
        if ($null -ne $obj.CustomOutputFolder) { $script:CustomOutputFolder = [string]$obj.CustomOutputFolder }
        if ($null -ne $obj.Language -and [string]$obj.Language -in @('ko','en','ja','es')) { $script:Language = [string]$obj.Language }
        if (-not [string]::IsNullOrWhiteSpace($script:CustomOutputFolder) -and -not (Test-Path -LiteralPath $script:CustomOutputFolder -PathType Container)) {
            $script:CustomOutputFolder = ''
        }
    } catch { }
}

function Save-AppSettings {
    try {
        if (-not (Test-Path -LiteralPath $script:SettingsDir -PathType Container)) {
            New-Item -ItemType Directory -Path $script:SettingsDir -Force | Out-Null
        }
        [pscustomobject]@{
            DarkMode = $script:DarkMode
            CustomOutputFolder = $script:CustomOutputFolder
            Language = $script:Language
        } | ConvertTo-Json | Set-Content -LiteralPath $script:SettingsPath -Encoding UTF8
    } catch { }
}

function Get-EngineAssemblyPaths {
    $names = @(
        'System.Runtime.CompilerServices.Unsafe.dll',
        'System.Buffers.dll',
        'System.Numerics.Vectors.dll',
        'System.Memory.dll',
        'ACadSharp.dll'
    )
    $paths = New-Object System.Collections.Generic.List[string]
    foreach ($name in $names) {
        $path = Join-Path $script:LibDir $name
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw (T 'engine.fileMissing' @($name))
        }
        $paths.Add($path)
    }
    return $paths.ToArray()
}

function Test-DwgCandidate([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return (T 'validate.emptyPath') }
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return (T 'validate.notFound') }
    if ([IO.Path]::GetExtension($Path).ToLowerInvariant() -ne '.dwg') { return (T 'validate.notDwg') }

    try {
        $bytes = New-Object byte[] 6
        $stream = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
        try {
            $read = $stream.Read($bytes, 0, 6)
        } finally {
            $stream.Dispose()
        }
        if ($read -lt 6) { return (T 'validate.badHeader') }
        $header = [Text.Encoding]::ASCII.GetString($bytes)
        if ($header -notmatch '^AC10[0-9]{2}$') { return (T 'validate.notRecognized') }
        if ($header -in @('AC1009','AC1012')) { return (T 'validate.oldVersion' @($header)) }
    }
    catch {
        return (T 'validate.failed' @($_.Exception.Message))
    }
    return $null
}

function Get-OutputFolderForInput([string]$InputPath) {
    if (-not [string]::IsNullOrWhiteSpace($script:CustomOutputFolder)) {
        return $script:CustomOutputFolder
    }
    return [IO.Path]::GetDirectoryName($InputPath)
}

function Set-FlatButton($button, [bool]$Accent = $false) {
    $button.FlatStyle = [Windows.Forms.FlatStyle]::Flat
    $button.FlatAppearance.BorderSize = 1
    $button.Cursor = [Windows.Forms.Cursors]::Hand
    if ($Accent) { $button.Tag = 'accent' } else { $button.Tag = 'normal' }
}

function Get-ThemeColors {
    if ($script:DarkMode) {
        return @{
            Bg = [Drawing.Color]::FromArgb(23,25,29)
            Surface = [Drawing.Color]::FromArgb(32,35,41)
            SurfaceAlt = [Drawing.Color]::FromArgb(42,46,53)
            Text = [Drawing.Color]::FromArgb(241,245,249)
            Muted = [Drawing.Color]::FromArgb(170,178,189)
            Border = [Drawing.Color]::FromArgb(58,64,72)
            Accent = [Drawing.Color]::FromArgb(43,111,190)
            AccentText = [Drawing.Color]::White
        }
    }
    return @{
        Bg = [Drawing.Color]::FromArgb(247,248,250)
        Surface = [Drawing.Color]::White
        SurfaceAlt = [Drawing.Color]::FromArgb(241,243,245)
        Text = [Drawing.Color]::FromArgb(31,41,55)
        Muted = [Drawing.Color]::FromArgb(107,114,128)
        Border = [Drawing.Color]::FromArgb(216,221,227)
        Accent = [Drawing.Color]::FromArgb(15,92,168)
        AccentText = [Drawing.Color]::White
    }
}

function Apply-ThemeToControl($control, $colors) {
    if ($null -eq $control) { return }

    if ($control -is [Windows.Forms.RichTextBox] -or $control -is [Windows.Forms.ListBox] -or $control -is [Windows.Forms.ComboBox]) {
        $control.BackColor = $colors.Surface
        $control.ForeColor = $colors.Text
    }
    elseif ($control -is [Windows.Forms.Button]) {
        $control.FlatStyle = [Windows.Forms.FlatStyle]::Flat
        $control.FlatAppearance.BorderColor = $colors.Border
        if ([string]$control.Tag -eq 'accent') {
            $control.BackColor = $colors.Accent
            $control.ForeColor = $colors.AccentText
            $control.FlatAppearance.BorderColor = $colors.Accent
        } else {
            $control.BackColor = $colors.Surface
            $control.ForeColor = $colors.Text
        }
    }
    elseif ($control -is [Windows.Forms.Panel] -or $control -is [Windows.Forms.Form]) {
        $control.BackColor = $colors.Bg
        $control.ForeColor = $colors.Text
    }
    elseif ($control -is [Windows.Forms.Label] -or $control -is [Windows.Forms.CheckBox] -or $control -is [Windows.Forms.RadioButton]) {
        $control.BackColor = [Drawing.Color]::Transparent
        $control.ForeColor = $colors.Text
    }

    if ($control.PSObject.Properties['Controls']) {
        foreach ($child in $control.Controls) { Apply-ThemeToControl $child $colors }
    }
}

function Apply-AppTheme {
    $colors = Get-ThemeColors
    Apply-ThemeToControl $form $colors

    $lblEngine.ForeColor = $colors.Muted
    $lblFoot.ForeColor = $colors.Muted
    if ($null -ne $lblFontWarning) {
        $lblFontWarning.ForeColor = $colors.Muted
    }
    $txtLog.BorderStyle = [Windows.Forms.BorderStyle]::FixedSingle
    $listFiles.BorderStyle = [Windows.Forms.BorderStyle]::FixedSingle

    $moreMenu.BackColor = $colors.Surface
    $moreMenu.ForeColor = $colors.Text
    $colorTable = [HjuMenuColorTable]::new([bool]$script:DarkMode)
    $moreMenu.Renderer = [System.Windows.Forms.ToolStripProfessionalRenderer]::new($colorTable)
    foreach ($item in $moreMenu.Items) {
        try { $item.ForeColor = $colors.Text } catch { }
        if ($item -is [Windows.Forms.ToolStripMenuItem]) {
            foreach ($sub in $item.DropDownItems) { try { $sub.ForeColor = $colors.Text } catch { } }
        }
    }

    $menuDarkMode.Checked = $script:DarkMode
    try { [HjuNative]::SetDarkTitleBar($form.Handle, $script:DarkMode) } catch { }

    if ($loadingPanel.Visible) {
        $loadingPanel.BackColor = $colors.Bg
        $lblLoading.ForeColor = $colors.Text
        $lblLoadingSub.ForeColor = $colors.Muted
    }
}

function Update-SaveFolderUI {
    $same = [string]::IsNullOrWhiteSpace($script:CustomOutputFolder)
    $menuSaveSame.Checked = $same
    $menuSaveCustom.Checked = -not $same
    if ($same) {
        $lblFoot.Text = T 'save.footerSame'
        $tip.SetToolTip($lblFoot, (T 'save.tipSame'))
    } else {
        $short = $script:CustomOutputFolder
        if ($short.Length -gt 40) { $short = '…' + $short.Substring($short.Length - 39) }
        $lblFoot.Text = T 'save.footerCustom' @($short)
        $tip.SetToolTip($lblFoot, $script:CustomOutputFolder)
    }
}

function Show-InvalidFiles($items) {
    if ($null -eq $items -or $items.Count -eq 0) { return }
    $lines = New-Object System.Collections.Generic.List[string]
    $max = [Math]::Min(7, $items.Count)
    for ($i = 0; $i -lt $max; $i++) { $lines.Add('• ' + $items[$i]) }
    if ($items.Count -gt $max) { $lines.Add((T 'common.moreCount' @(($items.Count - $max)))) }
    [Windows.Forms.MessageBox]::Show(
        (T 'invalid.message' @(($lines -join "`r`n"))),
        (T 'invalid.title'),
        [Windows.Forms.MessageBoxButtons]::OK,
        [Windows.Forms.MessageBoxIcon]::Warning
    ) | Out-Null
}

function Add-DwgPath([string]$Path) {
    $reason = Test-DwgCandidate $Path
    if ($null -ne $reason) {
        return "$([IO.Path]::GetFileName($Path)) — $reason"
    }
    foreach ($existing in $listFiles.Items) {
        if ([string]::Equals([string]$existing, $Path, [StringComparison]::OrdinalIgnoreCase)) { return $null }
    }
    [void]$listFiles.Items.Add($Path)
    Update-ConvertButton
    return $null
}

function Show-LoadingOverlay([string]$Title, [string]$SubText) {
    $lblLoading.Text = $Title
    $lblLoadingSub.Text = $SubText
    $loadingPanel.Visible = $true
    $loadingPanel.BringToFront()
    $form.UseWaitCursor = $true
    $loadingProgress.Style = [Windows.Forms.ProgressBarStyle]::Marquee
    $loadingProgress.MarqueeAnimationSpeed = 28
    [System.Windows.Forms.Application]::DoEvents()
}

function Hide-LoadingOverlay {
    $loadingProgress.MarqueeAnimationSpeed = 0
    $loadingPanel.Visible = $false
    $form.UseWaitCursor = $false
    $form.Refresh()
}

function Get-ProgramDescriptionText {
    switch ($script:Language) {
        'ko' { return @"
[프로그램 제작 의도]
AutoCAD 없이 외부 업체의 DWG 도면을 DXF로 변환해 LibreCAD에서 확인·수정할 수 있도록 만든 작은 전처리 도구입니다. 원본 DWG는 수정하지 않습니다.

CJK는 중국어(Chinese)·일본어(Japanese)·한국어(Korean) 문자를 뜻합니다. DWG의 원본 CAD 글꼴을 LibreCAD에서 렌더링하지 못하면 한글·일본어 가나·한자 같은 CJK 문자가 깨질 수 있습니다. wqy-unicode 변환 기능은 문자 내용을 바꾸지 않고 LibreCAD용 Unicode 글꼴 스타일로 연결합니다. LibreCAD에는 wqy-unicode.lff를 한 번 설치해야 합니다.

[DWG → DXF 변환]
1. DWG 파일을 창으로 끌어놓거나 [파일 추가]를 누릅니다.
2. 출력 형식은 기본값인 AutoCAD 2010 DXF 사용을 권장합니다.
3. 폰트 변환 방식을 선택합니다.
   · 변환 안 함: 원본 문자 스타일 유지
   · 전체 문자 변경 (권장): 문자/속성/치수 스타일을 wqy-unicode로 연결
   · CJK 포함 문자만 변경: 한글·히라가나·가타카나·일반적인 한자/CJK가 포함된 문자만 선택적으로 변경
4. [DXF 변환]을 누릅니다.
5. 생성된 DXF를 LibreCAD에서 열어 실제 도면을 확인합니다.

[CJK 포함 문자만 변경 주의]
영문·숫자 전용 스타일을 최대한 보존하기 위한 선택지입니다. 블록 내부 문자, 치수 문자, 특수 객체 등은 판별 또는 스타일 적용이 완전하지 않을 수 있으므로 중요한 도면은 변환 후 반드시 확인하세요.

[LibreCAD 글꼴]
1. [추가기능 → LibreCAD 폰트 받기]에서 wqy-unicode.lff를 저장합니다.
2. [추가기능 → 폰트폴더 열기]로 LibreCAD 글꼴 폴더를 엽니다.
3. 파일을 복사한 뒤 LibreCAD를 완전히 종료하고 다시 실행합니다.

[저장 위치]
기본값은 원본 DWG와 같은 폴더입니다. [추가기능 → 저장폴더 변경]에서 공통 저장폴더를 선택할 수 있습니다.

[변환 결과 확인]
생성한 DXF를 다시 읽고 주요 객체 수를 비교합니다. '확인 필요'가 표시되면 LibreCAD에서 원본과 대조해 주세요. Proxy/AEC/Civil 등 특수 객체는 완전한 변환을 보장하지 않습니다.
"@ }
        'ja' { return @"
[目的]
AutoCADを必要とせず、外部から受け取ったDWGをDXFへ変換し、LibreCADで確認・編集するための小さな前処理ツールです。元のDWGは変更しません。

CJKは中国語(Chinese)・日本語(Japanese)・韓国語(Korean)の文字を指します。元のCADフォントをLibreCADで表示できない場合、ハングル・かな・漢字などのCJK文字が文字化けすることがあります。wqy-unicode変換は文字内容を変更せず、LibreCAD向けUnicodeフォントスタイルへ接続します。LibreCADにはwqy-unicode.lffを一度インストールしてください。

[DWG → DXF]
1. DWGをウィンドウへドロップするか [ファイル追加] を選択します。
2. 出力は AutoCAD 2010 DXF を推奨します。
3. フォント変換を選択します。
   · 変換なし: 元の文字スタイルを維持
   · 全文字変更（推奨）: 文字・属性・寸法スタイルをwqy-unicodeへ接続
   · CJK文字のみ: ハングル、ひらがな、カタカナ、一般的な漢字/CJKを含む文字のみ変更
4. [DXF変換] を選択します。
5. LibreCADで結果を開き、図面を確認します。

[CJK文字のみの注意]
英数字のみのスタイルをできるだけ維持するためのモードです。ブロック内文字、寸法、特殊オブジェクトなどは完全に検出・適用できない場合があるため、重要な図面は変換後に確認してください。

[LibreCADフォント]
[その他 → LibreCADフォントを保存] で wqy-unicode.lff を保存し、[フォントフォルダを開く] からLibreCADのフォントフォルダへコピーして再起動してください。

[保存先]
初期設定では元のDWGと同じフォルダへ保存します。[その他 → 保存先] から共通の保存フォルダを指定できます。

[検証]
生成DXFを再読み込みして主要オブジェクト数を比較します。要確認の場合はLibreCADで元図面と比較してください。Proxy/AEC/Civilなどの特殊オブジェクトは完全な変換を保証しません。
"@ }
        'es' { return @"
[Objetivo]
Herramienta de preprocesamiento para convertir archivos DWG a DXF y revisarlos o editarlos en LibreCAD sin necesitar AutoCAD. El DWG original nunca se modifica.

CJK significa caracteres chinos, japoneses y coreanos. Si LibreCAD no puede representar la fuente CAD original, ese texto puede aparecer dañado. La conversión wqy-unicode mantiene el contenido del texto y cambia su estilo a una fuente Unicode compatible con LibreCAD. Instala wqy-unicode.lff una vez en LibreCAD.

[DWG → DXF]
1. Arrastra archivos DWG a la ventana o selecciona [Añadir].
2. Se recomienda AutoCAD 2010 DXF como salida.
3. Elige el modo de fuentes.
   · Sin cambios (Recomendado si el texto ya se muestra correctamente): conserva los estilos originales
   · Todo texto: úsalo cuando el texto CJK se vea dañado; vincula texto, atributos y cotas a wqy-unicode
   · Solo texto CJK: cambia únicamente texto con caracteres chinos, japoneses o coreanos e intenta conservar los estilos latinos y numéricos
4. Selecciona [Convertir a DXF].
5. Abre el resultado en LibreCAD y comprueba el dibujo.

[Nota sobre Solo CJK]
Este modo intenta conservar los estilos de texto latino y numérico. Algunos textos dentro de bloques, cotas u objetos especiales pueden no detectarse o aplicarse por completo. Comprueba siempre los dibujos importantes después de convertirlos.

[Fuente de LibreCAD]
Guarda wqy-unicode.lff desde [Opciones → Guardar fuente de LibreCAD], abre la carpeta de fuentes, copia el archivo y reinicia LibreCAD.

[Carpeta de salida]
De forma predeterminada, el DXF se guarda junto al DWG original. Puedes elegir una carpeta común desde [Opciones → Carpeta de salida].

[Validación]
El programa vuelve a leer el DXF generado y compara los recuentos principales de objetos. Si aparece Revisar, compara el resultado con el original en LibreCAD. No se garantiza la conversión perfecta de objetos Proxy/AEC/Civil u otros objetos especiales.
"@ }
        default { return @"
[Purpose]
A small preprocessing tool for converting DWG files to DXF so they can be reviewed and edited in LibreCAD without requiring AutoCAD. Original DWG files are never modified.

CJK means Chinese, Japanese, and Korean characters. If LibreCAD cannot render the original CAD font, CJK text may appear garbled. The wqy-unicode option keeps the text content and links its style to a LibreCAD-compatible Unicode font. Install wqy-unicode.lff in LibreCAD once.

[DWG → DXF]
1. Drop DWG files into the window or select [Add files].
2. AutoCAD 2010 DXF is recommended for output.
3. Choose a font conversion mode.
   · Keep original (Recommended when text already displays correctly): preserve original text styles
   · All text: use when CJK text is garbled; links text, attributes, and dimension styles to wqy-unicode
   · CJK text only: change only text containing Chinese, Japanese, or Korean characters while preserving Latin/numeric styles when possible
4. Select [Convert to DXF].
5. Open the result in LibreCAD and visually check the drawing.

[CJK-only note]
This mode is intended to preserve Latin/numeric-only styles. Text inside blocks, dimensions, or special objects may not always be detected or changed perfectly. Always verify important drawings after conversion.

[LibreCAD font]
Save wqy-unicode.lff from [Options → Download LibreCAD font], open the LibreCAD font folder, copy the file there, then fully restart LibreCAD.

[Output location]
By default the DXF is created next to the source DWG. A common output folder can be selected from [Options → Output folder].

[Validation]
The program re-reads the generated DXF and compares major object counts. If Review is shown, compare the result with the source in LibreCAD. Proxy/AEC/Civil and other special objects are not guaranteed to convert perfectly.
"@ }
    }
}

function Show-ProgramDescription {
    $dlg = New-Object System.Windows.Forms.Form
    $dlg.Text = T 'about.title'
    $dlg.StartPosition = 'CenterParent'
    $dlg.FormBorderStyle = 'FixedDialog'
    $dlg.MaximizeBox = $false
    $dlg.MinimizeBox = $false
    $dlg.ShowInTaskbar = $false
    $dlg.ClientSize = New-Object Drawing.Size(560, 545)
    $dlg.Font = New-Object Drawing.Font((Get-UiFontName), 9)
    try { if (Test-Path $script:IconResource) { $dlg.Icon = New-Object Drawing.Icon($script:IconResource) } } catch { }

    $title = New-Object Windows.Forms.Label
    $title.Text = 'DWG2DXF'
    $title.Font = New-Object Drawing.Font((Get-UiFontName), 14, [Drawing.FontStyle]::Bold)
    $title.AutoSize = $true
    $title.Location = New-Object Drawing.Point(18, 16)
    $dlg.Controls.Add($title)

    $ver = New-Object Windows.Forms.Label
    $ver.Text = T 'about.version' @($script:Version)
    $ver.AutoSize = $true
    $ver.Location = New-Object Drawing.Point(20, 48)
    $dlg.Controls.Add($ver)

    $box = New-Object Windows.Forms.RichTextBox
    $box.Location = New-Object Drawing.Point(18, 78)
    $box.Size = New-Object Drawing.Size(524, 408)
    $box.ReadOnly = $true
    $box.BorderStyle = 'None'
    $box.DetectUrls = $false
    $box.ScrollBars = 'Vertical'
    $box.Text = Get-ProgramDescriptionText
    $dlg.Controls.Add($box)

    $ok = New-Object Windows.Forms.Button
    $ok.Text = T 'common.ok'
    $ok.Size = New-Object Drawing.Size(82, 32)
    $ok.Location = New-Object Drawing.Point(460, 500)
    $ok.DialogResult = [Windows.Forms.DialogResult]::OK
    Set-FlatButton $ok $true
    $dlg.Controls.Add($ok)
    $dlg.AcceptButton = $ok

    $colors = Get-ThemeColors
    Apply-ThemeToControl $dlg $colors
    $ver.ForeColor = $colors.Muted
    $box.BackColor = $colors.Surface
    $box.ForeColor = $colors.Text
    $dlg.Add_Shown({ try { [HjuNative]::SetDarkTitleBar($dlg.Handle, $script:DarkMode) } catch { } })
    [void]$dlg.ShowDialog($form)
    $dlg.Dispose()
}

function Apply-Language {
    $fontName = Get-UiFontName
    $form.Font = New-Object Drawing.Font($fontName, 9)
    $moreMenu.Font = New-Object Drawing.Font($fontName, 9)
    $lblTitle.Font = New-Object Drawing.Font($fontName, 13, [Drawing.FontStyle]::Bold)
    $lblLoading.Font = New-Object Drawing.Font($fontName, 15, [Drawing.FontStyle]::Bold)
    $lblFontWarning.Font = New-Object Drawing.Font($fontName, 8)

    $lblEngine.Text = T $script:EngineStatusKey
    $btnMore.Text = (T 'menu.more') + '  ▾'
    $menuDescription.Text = T 'menu.about'
    $menuLanguage.Text = T 'menu.language'
    $menuDarkMode.Text = T 'menu.dark'
    $menuSaveFolder.Text = T 'menu.save'
    $menuSaveSame.Text = T 'menu.saveSame'
    $menuSaveCustom.Text = T 'menu.saveCustom'
    $menuGetFont.Text = T 'menu.getFont'
    $menuOpenFont.Text = T 'menu.openFont'

    $menuLangKo.Checked = ($script:Language -eq 'ko')
    $menuLangEn.Checked = ($script:Language -eq 'en')
    $menuLangJa.Checked = ($script:Language -eq 'ja')
    $menuLangEs.Checked = ($script:Language -eq 'es')

    $btnAdd.Text = T 'button.add'
    $btnRemove.Text = T 'button.remove'
    $btnClear.Text = T 'button.clear'
    $lblVersion.Text = T 'label.output'

    $selectedVersion = $cmbVersion.SelectedIndex
    $cmbVersion.Items.Clear()
    [void]$cmbVersion.Items.Add((T 'output.2010'))
    [void]$cmbVersion.Items.Add((T 'output.original'))
    if ($selectedVersion -lt 0) { $selectedVersion = 0 }
    $cmbVersion.SelectedIndex = $selectedVersion

    $lblFontMode.Text = T 'label.font'
    $radFontNone.Text = T 'font.none'
    $radFontAll.Text = T 'font.all'
    $radFontCjk.Text = T 'font.cjk'
    $lblFontWarning.Text = T 'font.help'
    $tip.SetToolTip($radFontNone, (T 'tip.fontNone'))
    $tip.SetToolTip($radFontAll, (T 'tip.fontAll'))
    $tip.SetToolTip($radFontCjk, (T 'tip.fontCjk'))
    $btnConvert.Text = T 'button.convert'

    if ($loadingPanel.Visible) {
        $lblLoading.Text = T 'loading.title'
        $lblLoadingSub.Text = T 'loading.sub'
    }

    Update-SaveFolderUI
    Apply-AppTheme
}

function Set-RecommendedFontModeForLanguage {
    # UI language only sets the initial/recommended choice.
    # All three options remain available in every language because drawing text
    # and application UI language are independent.
    if ($script:Language -in @('ko','ja')) {
        $radFontAll.Checked = $true
    } else {
        $radFontNone.Checked = $true
    }
    $radFontCjk.Checked = $false
}

function Set-AppLanguage([string]$Code) {
    if ($Code -notin @('ko','en','ja','es')) { return }
    $script:Language = $Code
    Set-RecommendedFontModeForLanguage
    Save-AppSettings
    Apply-Language
}

Load-AppSettings

# ---------- GUI ----------
$form = New-Object System.Windows.Forms.Form
$form.Text = 'DWG2DXF'
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false
$form.MinimizeBox = $true
$form.ClientSize = New-Object System.Drawing.Size(620, 500)
$form.Font = New-Object System.Drawing.Font('Malgun Gothic', 9)
$form.AllowDrop = $true
try { if (Test-Path $script:IconResource) { $form.Icon = New-Object Drawing.Icon($script:IconResource) } } catch { }

$picLogo = New-Object System.Windows.Forms.PictureBox
$picLogo.Location = New-Object Drawing.Point(16, 10)
$picLogo.Size = New-Object Drawing.Size(30, 30)
$picLogo.SizeMode = 'Zoom'
try {
    if (Test-Path $script:LogoResource) { $picLogo.Image = [Drawing.Image]::FromFile($script:LogoResource) }
    elseif ($null -ne $form.Icon) { $picLogo.Image = $form.Icon.ToBitmap() }
} catch { }
$form.Controls.Add($picLogo)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = 'DWG2DXF'
$lblTitle.Font = New-Object System.Drawing.Font('Malgun Gothic', 13, [Drawing.FontStyle]::Bold)
$lblTitle.AutoSize = $true
$lblTitle.Location = New-Object Drawing.Point(54, 11)
$form.Controls.Add($lblTitle)

$lblEngine = New-Object System.Windows.Forms.Label
$lblEngine.Text = '변환 엔진 준비 중'
$lblEngine.AutoSize = $true
$lblEngine.Location = New-Object Drawing.Point(157, 17)
$form.Controls.Add($lblEngine)

$btnMore = New-Object System.Windows.Forms.Button
$btnMore.Text = '추가기능  ▾'
$btnMore.Location = New-Object Drawing.Point(507, 8)
$btnMore.Size = New-Object Drawing.Size(97, 32)
Set-FlatButton $btnMore
$form.Controls.Add($btnMore)

$moreMenu = New-Object System.Windows.Forms.ContextMenuStrip
$moreMenu.ShowImageMargin = $false
$moreMenu.Font = New-Object Drawing.Font('Malgun Gothic', 9)
$menuDescription = New-Object System.Windows.Forms.ToolStripMenuItem
$menuDescription.Text = '프로그램 설명'
[void]$moreMenu.Items.Add($menuDescription)

$menuLanguage = New-Object System.Windows.Forms.ToolStripMenuItem
$menuLanguage.Text = '언어 (Language)'
$menuLangKo = New-Object System.Windows.Forms.ToolStripMenuItem
$menuLangKo.Text = '한국어'
$menuLangEn = New-Object System.Windows.Forms.ToolStripMenuItem
$menuLangEn.Text = 'English'
$menuLangJa = New-Object System.Windows.Forms.ToolStripMenuItem
$menuLangJa.Text = '日本語'
$menuLangEs = New-Object System.Windows.Forms.ToolStripMenuItem
$menuLangEs.Text = 'Español'
[void]$menuLanguage.DropDownItems.Add($menuLangKo)
[void]$menuLanguage.DropDownItems.Add($menuLangEn)
[void]$menuLanguage.DropDownItems.Add($menuLangJa)
[void]$menuLanguage.DropDownItems.Add($menuLangEs)
[void]$moreMenu.Items.Add($menuLanguage)

[void]$moreMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
$menuDarkMode = New-Object System.Windows.Forms.ToolStripMenuItem
$menuDarkMode.Text = '다크 모드'
$menuDarkMode.CheckOnClick = $true
[void]$moreMenu.Items.Add($menuDarkMode)
[void]$moreMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
$menuSaveFolder = New-Object System.Windows.Forms.ToolStripMenuItem
$menuSaveFolder.Text = '저장폴더 변경'
$menuSaveSame = New-Object System.Windows.Forms.ToolStripMenuItem
$menuSaveSame.Text = '원본 DWG와 같은 폴더'
$menuSaveSame.CheckOnClick = $false
$menuSaveCustom = New-Object System.Windows.Forms.ToolStripMenuItem
$menuSaveCustom.Text = '다른 폴더 선택...'
$menuSaveCustom.CheckOnClick = $false
[void]$menuSaveFolder.DropDownItems.Add($menuSaveSame)
[void]$menuSaveFolder.DropDownItems.Add($menuSaveCustom)
[void]$moreMenu.Items.Add($menuSaveFolder)
[void]$moreMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
$menuGetFont = New-Object System.Windows.Forms.ToolStripMenuItem
$menuGetFont.Text = 'LibreCAD폰트 받기'
[void]$moreMenu.Items.Add($menuGetFont)
$menuOpenFont = New-Object System.Windows.Forms.ToolStripMenuItem
$menuOpenFont.Text = '폰트폴더 열기'
[void]$moreMenu.Items.Add($menuOpenFont)

$listFiles = New-Object System.Windows.Forms.ListBox
$listFiles.Location = New-Object Drawing.Point(16, 50)
$listFiles.Size = New-Object Drawing.Size(588, 128)
$listFiles.HorizontalScrollbar = $true
$listFiles.SelectionMode = 'MultiExtended'
$form.Controls.Add($listFiles)

$btnAdd = New-Object System.Windows.Forms.Button
$btnAdd.Text = '파일 추가'
$btnAdd.Location = New-Object Drawing.Point(16, 188)
$btnAdd.Size = New-Object Drawing.Size(84, 30)
Set-FlatButton $btnAdd
$form.Controls.Add($btnAdd)

$btnRemove = New-Object System.Windows.Forms.Button
$btnRemove.Text = '선택 삭제'
$btnRemove.Location = New-Object Drawing.Point(106, 188)
$btnRemove.Size = New-Object Drawing.Size(84, 30)
Set-FlatButton $btnRemove
$form.Controls.Add($btnRemove)

$btnClear = New-Object System.Windows.Forms.Button
$btnClear.Text = '전체 삭제'
$btnClear.Location = New-Object Drawing.Point(196, 188)
$btnClear.Size = New-Object Drawing.Size(84, 30)
Set-FlatButton $btnClear
$form.Controls.Add($btnClear)

$lblVersion = New-Object System.Windows.Forms.Label
$lblVersion.Text = '출력'
$lblVersion.AutoSize = $true
$lblVersion.Location = New-Object Drawing.Point(303, 196)
$form.Controls.Add($lblVersion)

$cmbVersion = New-Object System.Windows.Forms.ComboBox
$cmbVersion.DropDownStyle = 'DropDownList'
$cmbVersion.Location = New-Object Drawing.Point(344, 191)
$cmbVersion.Size = New-Object Drawing.Size(260, 28)
[void]$cmbVersion.Items.Add('AutoCAD 2010 DXF (권장 / LibreCAD용)')
[void]$cmbVersion.Items.Add('원본 DWG 버전 유지')
$cmbVersion.SelectedIndex = 0
$form.Controls.Add($cmbVersion)

$panelFont = New-Object System.Windows.Forms.Panel
$panelFont.Location = New-Object Drawing.Point(16, 226)
$panelFont.Size = New-Object Drawing.Size(588, 92)
$panelFont.BorderStyle = [Windows.Forms.BorderStyle]::FixedSingle
$form.Controls.Add($panelFont)

$lblFontMode = New-Object System.Windows.Forms.Label
$lblFontMode.Text = '폰트 변환'
$lblFontMode.AutoSize = $true
$lblFontMode.Location = New-Object Drawing.Point(12, 10)
$panelFont.Controls.Add($lblFontMode)

$lblFontWarning = New-Object System.Windows.Forms.Label
$lblFontWarning.Text = 'CJK = 중국어·일본어·한국어 문자. LibreCAD에서 관련 문자가 깨질 때 사용하는 기능입니다.'
$lblFontWarning.AutoSize = $true
$lblFontWarning.MaximumSize = New-Object Drawing.Size(458, 0)
$lblFontWarning.Font = New-Object Drawing.Font('Malgun Gothic', 8)
$lblFontWarning.Location = New-Object Drawing.Point(110, 10)
$lblFontWarning.Visible = $true
$panelFont.Controls.Add($lblFontWarning)

$radFontNone = New-Object System.Windows.Forms.RadioButton
$radFontNone.Text = '변환 안 함'
$radFontNone.AutoSize = $true
$radFontNone.Location = New-Object Drawing.Point(14, 58)
$panelFont.Controls.Add($radFontNone)

$radFontAll = New-Object System.Windows.Forms.RadioButton
$radFontAll.Text = '전체 문자 변경 (권장)'
$radFontAll.AutoSize = $true
$radFontAll.Location = New-Object Drawing.Point(152, 58)
$panelFont.Controls.Add($radFontAll)

$radFontCjk = New-Object System.Windows.Forms.RadioButton
$radFontCjk.Text = '한·중·일(CJK) 문자만 변경'
$radFontCjk.AutoSize = $true
$radFontCjk.Location = New-Object Drawing.Point(336, 58)
$panelFont.Controls.Add($radFontCjk)

$tip = New-Object System.Windows.Forms.ToolTip
$tip.SetToolTip($radFontNone, '원본 문자 스타일을 그대로 유지합니다.')
$tip.SetToolTip($radFontAll, 'CJK 문자가 깨질 때 가장 안정적인 방식입니다. 모든 대상 문자와 치수 문자 스타일을 wqy-unicode로 연결합니다.')
$tip.SetToolTip($radFontCjk, '한글, 일본어 가나, 한자 등 한·중·일(CJK) 문자가 포함된 문자만 선택적으로 변경합니다.')

Set-RecommendedFontModeForLanguage

$btnConvert = New-Object System.Windows.Forms.Button
$btnConvert.Text = 'DXF 변환'
$btnConvert.Location = New-Object Drawing.Point(16, 328)
$btnConvert.Size = New-Object Drawing.Size(116, 38)
$btnConvert.Enabled = $false
Set-FlatButton $btnConvert $true
$form.Controls.Add($btnConvert)

$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object Drawing.Point(142, 336)
$progress.Size = New-Object Drawing.Size(462, 22)
$progress.Minimum = 0
$progress.Maximum = 100
$form.Controls.Add($progress)

$txtLog = New-Object System.Windows.Forms.RichTextBox
$txtLog.Location = New-Object Drawing.Point(16, 378)
$txtLog.Size = New-Object Drawing.Size(588, 82)
$txtLog.ReadOnly = $true
$txtLog.WordWrap = $false
$txtLog.ScrollBars = 'Vertical'
$form.Controls.Add($txtLog)

$lblFoot = New-Object System.Windows.Forms.Label
$lblFoot.AutoSize = $true
$lblFoot.Location = New-Object Drawing.Point(16, 472)
$form.Controls.Add($lblFoot)

# Full-window loading overlay. Engine assemblies are loaded on a background task,
# so Windows continues repainting the form instead of showing "응답 없음".
$loadingPanel = New-Object System.Windows.Forms.Panel
$loadingPanel.Dock = 'Fill'
$loadingPanel.Visible = $true

$loadingLogo = New-Object Windows.Forms.PictureBox
$loadingLogo.Size = New-Object Drawing.Size(72,72)
$loadingLogo.Location = New-Object Drawing.Point(274, 105)
$loadingLogo.SizeMode = 'Zoom'
try {
    if (Test-Path $script:LogoResource) { $loadingLogo.Image = [Drawing.Image]::FromFile($script:LogoResource) }
    elseif ($null -ne $form.Icon) { $loadingLogo.Image = $form.Icon.ToBitmap() }
} catch { }
$loadingPanel.Controls.Add($loadingLogo)

$lblLoading = New-Object Windows.Forms.Label
$lblLoading.Text = '변환 엔진을 불러오는 중...'
$lblLoading.Font = New-Object Drawing.Font('Malgun Gothic', 15, [Drawing.FontStyle]::Bold)
$lblLoading.TextAlign = 'MiddleCenter'
$lblLoading.Size = New-Object Drawing.Size(520,38)
$lblLoading.Location = New-Object Drawing.Point(50, 190)
$loadingPanel.Controls.Add($lblLoading)

$lblLoadingSub = New-Object Windows.Forms.Label
$lblLoadingSub.Text = 'PC 상태에 따라 잠시 시간이 걸릴 수 있습니다.'
$lblLoadingSub.TextAlign = 'MiddleCenter'
$lblLoadingSub.Size = New-Object Drawing.Size(520,26)
$lblLoadingSub.Location = New-Object Drawing.Point(50, 232)
$loadingPanel.Controls.Add($lblLoadingSub)

$loadingProgress = New-Object Windows.Forms.ProgressBar
$loadingProgress.Style = 'Marquee'
$loadingProgress.MarqueeAnimationSpeed = 28
$loadingProgress.Size = New-Object Drawing.Size(260,10)
$loadingProgress.Location = New-Object Drawing.Point(180, 274)
$loadingPanel.Controls.Add($loadingProgress)
$form.Controls.Add($loadingPanel)
$loadingPanel.BringToFront()

function Add-Log([string]$Message) {
    $txtLog.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $Message`r`n")
    $txtLog.SelectionStart = $txtLog.TextLength
    $txtLog.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

function Update-ConvertButton {
    $btnConvert.Enabled = $script:EngineReady -and ($listFiles.Items.Count -gt 0)
}

function Set-FileStageProgress([int]$FileNumber, [int]$TotalFiles, [int]$StagePercent) {
    if ($TotalFiles -le 0) { return }
    $base = ($FileNumber - 1) / [double]$TotalFiles
    $part = ($StagePercent / 100.0) / [double]$TotalFiles
    $pct = [int](($base + $part) * 100)
    if ($pct -lt 0) { $pct = 0 }
    if ($pct -gt 100) { $pct = 100 }
    $progress.Value = $pct
    [System.Windows.Forms.Application]::DoEvents()
}

Apply-Language

$btnMore.Add_Click({
    $moreMenu.Show($btnMore, (New-Object Drawing.Point(0, $btnMore.Height)))
})

$menuDescription.Add_Click({ Show-ProgramDescription })
$menuLangKo.Add_Click({ Set-AppLanguage 'ko' })
$menuLangEn.Add_Click({ Set-AppLanguage 'en' })
$menuLangJa.Add_Click({ Set-AppLanguage 'ja' })
$menuLangEs.Add_Click({ Set-AppLanguage 'es' })

$menuDarkMode.Add_Click({
    $script:DarkMode = [bool]$menuDarkMode.Checked
    Save-AppSettings
    Apply-AppTheme
})

$menuSaveSame.Add_Click({
    $script:CustomOutputFolder = ''
    Save-AppSettings
    Update-SaveFolderUI
})

$menuSaveCustom.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = T 'dialog.outputFolder'
    if (-not [string]::IsNullOrWhiteSpace($script:CustomOutputFolder) -and (Test-Path $script:CustomOutputFolder -PathType Container)) {
        $dlg.SelectedPath = $script:CustomOutputFolder
    }
    if ($dlg.ShowDialog() -eq [Windows.Forms.DialogResult]::OK) {
        $script:CustomOutputFolder = $dlg.SelectedPath
        Save-AppSettings
        Update-SaveFolderUI
    }
})

$menuGetFont.Add_Click({
    try {
        if (-not (Test-Path -LiteralPath $script:FontResource -PathType Leaf)) {
            throw (T 'dialog.fontMissing')
        }
        $dlg = New-Object System.Windows.Forms.SaveFileDialog
        $dlg.Filter = T 'dialog.fontFilter'
        $dlg.FileName = 'wqy-unicode.lff'
        $dlg.Title = T 'dialog.fontSaveTitle'
        $downloads = Join-Path ([Environment]::GetFolderPath('UserProfile')) 'Downloads'
        if (Test-Path -LiteralPath $downloads -PathType Container) { $dlg.InitialDirectory = $downloads }
        if ($dlg.ShowDialog() -eq [Windows.Forms.DialogResult]::OK) {
            Copy-Item -LiteralPath $script:FontResource -Destination $dlg.FileName -Force
            [Windows.Forms.MessageBox]::Show(
                (T 'dialog.fontSaved' @($dlg.FileName)),
                (T 'dialog.fontDownloadTitle'),
                [Windows.Forms.MessageBoxButtons]::OK,
                [Windows.Forms.MessageBoxIcon]::Information
            ) | Out-Null
        }
    } catch {
        [Windows.Forms.MessageBox]::Show($_.Exception.Message, (T 'dialog.fontDownloadTitle'), [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
})

$menuOpenFont.Add_Click({
    $fontFolder = Get-LibreCadFontFolder
    if (-not [string]::IsNullOrWhiteSpace($fontFolder)) {
        Start-Process explorer.exe -ArgumentList ('"' + $fontFolder + '"')
        return
    }
    $msg = T 'dialog.fontFolderMessage'
    $answer = [Windows.Forms.MessageBox]::Show($msg, (T 'dialog.fontFolderTitle'), [Windows.Forms.MessageBoxButtons]::YesNo, [Windows.Forms.MessageBoxIcon]::Information)
    if ($answer -eq [Windows.Forms.DialogResult]::Yes) {
        $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
        $dlg.Description = T 'dialog.fontFolderChoose'
        if (-not [string]::IsNullOrWhiteSpace($env:ProgramFiles)) { $dlg.SelectedPath = $env:ProgramFiles }
        if ($dlg.ShowDialog() -eq [Windows.Forms.DialogResult]::OK) {
            Start-Process explorer.exe -ArgumentList ('"' + $dlg.SelectedPath + '"')
        }
    }
})

$btnAdd.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = T 'dialog.dwgFilter'
    $dlg.Multiselect = $true
    $dlg.Title = T 'dialog.dwgOpenTitle'
    if ($dlg.ShowDialog() -eq [Windows.Forms.DialogResult]::OK) {
        $invalid = New-Object System.Collections.Generic.List[string]
        foreach ($p in $dlg.FileNames) {
            $reason = Add-DwgPath $p
            if ($null -ne $reason) { $invalid.Add($reason) }
        }
        Show-InvalidFiles $invalid
    }
})

$btnRemove.Add_Click({
    $indices = @($listFiles.SelectedIndices | Sort-Object -Descending)
    foreach ($i in $indices) { $listFiles.Items.RemoveAt([int]$i) }
    Update-ConvertButton
})

$btnClear.Add_Click({
    $listFiles.Items.Clear()
    Update-ConvertButton
})

$form.Add_DragEnter({
    param($sender, $e)
    if ($e.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) {
        $e.Effect = [Windows.Forms.DragDropEffects]::Copy
    } else {
        $e.Effect = [Windows.Forms.DragDropEffects]::None
    }
})

$form.Add_DragDrop({
    param($sender, $e)
    $paths = $e.Data.GetData([Windows.Forms.DataFormats]::FileDrop)
    $invalid = New-Object System.Collections.Generic.List[string]
    foreach ($p in $paths) {
        $reason = Add-DwgPath $p
        if ($null -ne $reason) { $invalid.Add($reason) }
    }
    Show-InvalidFiles $invalid
})

$btnConvert.Add_Click({
    if (-not $script:EngineReady -or $listFiles.Items.Count -eq 0) { return }

    $btnConvert.Enabled = $false
    $btnAdd.Enabled = $false
    $btnRemove.Enabled = $false
    $btnClear.Enabled = $false
    $progress.Value = 0
    $form.UseWaitCursor = $true

    $okCount = 0
    $warnCount = 0
    $failCount = 0
    $totalFiles = $listFiles.Items.Count
    $current = 0

    foreach ($item in @($listFiles.Items)) {
        $current++
        $inputPath = [string]$item
        $name = [IO.Path]::GetFileName($inputPath)
        Add-Log (T 'log.reading' @($current, $totalFiles, $name))
        Set-FileStageProgress $current $totalFiles 8

        try {
            $outFolder = Get-OutputFolderForInput $inputPath
            if (-not (Test-Path -LiteralPath $outFolder -PathType Container)) {
                throw (T 'error.outputFolder' @($outFolder))
            }

            $outputPath = Get-OutputPath -InputPath $inputPath -OutputFolder $outFolder
            $reader = [ACadSharp.IO.DwgReader]::new($inputPath)
            Set-FileStageProgress $current $totalFiles 15
            try { $doc = $reader.Read() } finally { if ($null -ne $reader) { $reader.Dispose() } }
            if ($null -eq $doc) { throw (T 'error.readDwg') }
            Set-FileStageProgress $current $totalFiles 48

            $before = Get-DocStats $doc
            if ($cmbVersion.SelectedIndex -eq 0) { try { $doc.Header.Version = [ACadSharp.ACadVersion]::AC1024 } catch { } }

            $fontMode = 'None'
            if ($radFontAll.Checked) { $fontMode = 'All' }
            elseif ($radFontCjk.Checked) { $fontMode = 'CjkOnly' }

            $fontResult = $null
            Set-FileStageProgress $current $totalFiles 58
            if ($fontMode -eq 'All') {
                $fontResult = Set-WqyUnicodeStyle $doc 'All'
                Add-Log (T 'log.fontAll' @($fontResult.TextEntities, $fontResult.Attributes, $fontResult.DimensionStyles))
            }
            elseif ($fontMode -eq 'CjkOnly') {
                $fontResult = Set-WqyUnicodeStyle $doc 'CjkOnly'
                if ($fontResult.TotalApplied -gt 0) {
                    Add-Log (T 'log.fontCjk' @($fontResult.TextEntities, $fontResult.Attributes))
                } else {
                    Add-Log (T 'log.fontCjkNone')
                }
            }
            else {
                Add-Log (T 'log.fontNone')
            }

            Set-FileStageProgress $current $totalFiles 72
            $writer = [ACadSharp.IO.DxfWriter]::new($outputPath, $doc, $false)
            try { $writer.Write() } finally { if ($null -ne $writer) { $writer.Dispose() } }

            if (-not (Test-Path -LiteralPath $outputPath -PathType Leaf)) { throw (T 'error.noDxf') }
            if ((Get-Item -LiteralPath $outputPath).Length -le 0) { throw (T 'error.emptyDxf') }
            Set-FileStageProgress $current $totalFiles 86

            $dxfReader = [ACadSharp.IO.DxfReader]::new($outputPath)
            try { $dxfDoc = $dxfReader.Read() } finally { if ($null -ne $dxfReader) { $dxfReader.Dispose() } }
            if ($null -eq $dxfDoc) { throw (T 'error.verifyDxf') }
            Set-FileStageProgress $current $totalFiles 95

            $after = Get-DocStats $dxfDoc
            $diffs = Compare-Stats $before $after

            if ($fontMode -ne 'None' -and $null -ne $fontResult -and $fontResult.TotalApplied -gt 0) {
                $fontUsage = Get-WqyUnicodeUsage $dxfDoc
                if (-not $fontUsage.StyleExists) {
                    $diffs.Add((T 'diff.fontStyleMissing'))
                } elseif ($fontUsage.TextEntities -eq 0 -and $fontUsage.DimensionStyles -eq 0) {
                    $diffs.Add((T 'diff.fontUsageZero'))
                } else {
                    Add-Log (T 'log.fontVerified' @($fontUsage.TextEntities, $fontUsage.DimensionStyles))
                }
            }

            if ($diffs.Count -eq 0) {
                $okCount++
                Add-Log (T 'log.ok' @([IO.Path]::GetFileName($outputPath), $after.Total, $after.Layers, $after.Text))
            } else {
                $warnCount++
                Add-Log (T 'log.review' @([IO.Path]::GetFileName($outputPath)))
                Add-Log (T 'log.changes' @(($diffs -join ', ')))
            }
        }
        catch {
            $failCount++
            Add-Log (T 'log.fail' @($_.Exception.Message))
        }
        finally {
            $doc = $null
            $dxfDoc = $null
            [GC]::Collect()
            [GC]::WaitForPendingFinalizers()
        }

        $pct = [int](($current / [double]$totalFiles) * 100)
        if ($pct -gt 100) { $pct = 100 }
        $progress.Value = $pct
        [System.Windows.Forms.Application]::DoEvents()
    }

    Add-Log (T 'log.summary' @($okCount, $warnCount, $failCount))
    if ($warnCount -gt 0) { Add-Log (T 'log.reviewAdvice') }

    $btnAdd.Enabled = $true
    $btnRemove.Enabled = $true
    $btnClear.Enabled = $true
    $form.UseWaitCursor = $false
    Update-ConvertButton
})

$engineTimer = New-Object Windows.Forms.Timer
$engineTimer.Interval = 160
$engineTimer.Add_Tick({
    if ($null -eq $script:EngineLoadTask) { return }
    if (-not $script:EngineLoadTask.IsCompleted) { return }
    $engineTimer.Stop()
    try {
        $errorText = $script:EngineLoadTask.Result
        if (-not [string]::IsNullOrWhiteSpace($errorText)) { throw $errorText }
        $script:EngineReady = $true
        $script:EngineStatusKey = 'engine.ready'
        $lblEngine.Text = T $script:EngineStatusKey
        Add-Log (T 'log.ready')
        if (Test-Path -LiteralPath $script:FontResource -PathType Leaf) { Add-Log (T 'log.fontBundled') }
        Hide-LoadingOverlay
        Update-ConvertButton
        Apply-AppTheme
    }
    catch {
        $script:EngineReady = $false
        $script:EngineStatusKey = 'engine.failed'
        $lblEngine.Text = T $script:EngineStatusKey
        $msg = $_.Exception.Message
        Write-StartupError $msg
        Add-Log (T 'log.engineFailed' @($msg))
        Hide-LoadingOverlay
        [Windows.Forms.MessageBox]::Show(
            (T 'error.enginePrepare' @($msg)),
            'DWG2DXF',
            [Windows.Forms.MessageBoxButtons]::OK,
            [Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
    finally {
        $script:Initializing = $false
    }
})

$form.Add_Shown({
    try {
        Apply-AppTheme
        Update-SaveFolderUI
        Show-LoadingOverlay (T 'loading.title') (T 'loading.sub')

        if ($script:Initializing -or $script:EngineReady) { return }
        $script:Initializing = $true
        if (-not (Test-NetFramework48)) {
            throw (T 'error.net48')
        }
        Add-Log (T 'log.engineCheck')
        $paths = Get-EngineAssemblyPaths
        $script:EngineLoadTask = [HjuEngineLoader]::LoadAsync($paths)
        $engineTimer.Start()
    }
    catch {
        $script:Initializing = $false
        Hide-LoadingOverlay
        $msg = $_.Exception.Message
        Write-StartupError $msg
        $script:EngineStatusKey = 'engine.failed'
        $lblEngine.Text = T $script:EngineStatusKey
        Add-Log (T 'log.engineFailed' @($msg))
        [Windows.Forms.MessageBox]::Show($msg, 'DWG2DXF', [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
})

$form.Add_FormClosed({
    Save-AppSettings
    try { if ($null -ne $picLogo.Image) { $picLogo.Image.Dispose() } } catch { }
    try { if ($null -ne $loadingLogo.Image) { $loadingLogo.Image.Dispose() } } catch { }
})

try {
    [void]$form.ShowDialog()
}
catch {
    Write-StartupError $_.Exception.ToString()
    try { [Windows.Forms.MessageBox]::Show($_.Exception.Message, (T 'error.app')) | Out-Null } catch { }
}
