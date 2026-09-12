using System.Collections;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;
using ACadSharp;
using ACadSharp.IO;
using ACadSharp.Tables;
using DWG2DXF.Web.Models;

namespace DWG2DXF.Web.Services;

public sealed class CadConversionService
{
    public const long DefaultMaxFileSize = 256L * 1024 * 1024;
    private static readonly Regex HangulRegex = new("[\\u1100-\\u11FF\\u3130-\\u318F\\uA960-\\uA97F\\uAC00-\\uD7AF\\uD7B0-\\uD7FF]", RegexOptions.Compiled);

    public async Task<(string? Header, string? Error)> ValidateBrowserFileAsync(
        Microsoft.AspNetCore.Components.Forms.IBrowserFile file,
        CancellationToken cancellationToken = default)
    {
        if (!file.Name.EndsWith(".dwg", StringComparison.OrdinalIgnoreCase))
            return (null, "DWG 파일만 추가할 수 있습니다.");

        if (file.Size < 6)
            return (null, "DWG 파일 헤더가 올바르지 않습니다.");

        if (file.Size > DefaultMaxFileSize)
            return (null, $"현재 웹 버전의 단일 파일 제한은 {DefaultMaxFileSize / 1024 / 1024} MB입니다.");

        await using var stream = file.OpenReadStream(DefaultMaxFileSize, cancellationToken);
        var buffer = new byte[6];
        var read = await stream.ReadAsync(buffer.AsMemory(0, 6), cancellationToken);
        if (read < 6)
            return (null, "DWG 파일 헤더가 올바르지 않습니다.");

        var header = Encoding.ASCII.GetString(buffer);
        if (!Regex.IsMatch(header, "^AC10[0-9]{2}$"))
            return (header, "DWG 형식으로 인식할 수 없습니다.");

        if (header is "AC1009" or "AC1012")
            return (header, $"현재 변환 엔진에서 지원하지 않는 오래된 DWG 버전입니다. ({header})");

        return (header, null);
    }

    public async Task<ConversionResult> ConvertAsync(
        Microsoft.AspNetCore.Components.Forms.IBrowserFile file,
        ConversionOptions options,
        Action<string>? log = null,
        CancellationToken cancellationToken = default)
    {
        log?.Invoke($"{file.Name} 읽는 중...");

        await using var browserStream = file.OpenReadStream(DefaultMaxFileSize, cancellationToken);
        using var input = new MemoryStream((int)Math.Min(file.Size, int.MaxValue));
        await browserStream.CopyToAsync(input, cancellationToken);
        input.Position = 0;

        CadDocument doc;
        using (var reader = new DwgReader(input))
        {
            doc = reader.Read() ?? throw new InvalidOperationException("DWG 문서를 읽지 못했습니다.");
        }

        var before = GetDocStats(doc);

        if (options.OutputVersion == OutputVersionMode.AutoCad2010)
        {
            doc.Header.Version = ACadVersion.AC1024;
            log?.Invoke("출력 버전: AutoCAD 2010 DXF (AC1024)");
        }
        else
        {
            log?.Invoke($"출력 버전: 원본 유지 ({doc.Header.Version})");
        }

        FontApplyResult? fontResult = null;
        switch (options.FontMode)
        {
            case FontMode.All:
                fontResult = SetWqyUnicodeStyle(doc, FontMode.All);
                log?.Invoke($"글꼴: 전체 문자 wqy-unicode 적용 (문자 {fontResult.TextEntities}, 속성 {fontResult.Attributes}, 치수스타일 {fontResult.DimensionStyles})");
                break;
            case FontMode.KoreanOnly:
                fontResult = SetWqyUnicodeStyle(doc, FontMode.KoreanOnly);
                log?.Invoke(fontResult.TotalApplied > 0
                    ? $"글꼴: 한글 포함 문자만 wqy-unicode 적용 (문자 {fontResult.TextEntities}, 속성 {fontResult.Attributes})"
                    : "글꼴: 한글 포함 문자를 찾지 못해 원본 문자 스타일을 유지했습니다.");
                break;
            default:
                log?.Invoke("글꼴: 변환하지 않음 (원본 문자 스타일 유지)");
                break;
        }

        byte[] dxfBytes;

        using (var output = new MemoryStream())
        {
            var writer = new DxfWriter(output, doc, binary: false);
            // ACadSharp의 DxfWriter.Dispose()는 내부 StreamWriter와 원본 스트림을 닫습니다.
            // 따라서 Write()가 Flush()를 끝낸 직후 바이트를 먼저 복사한 다음 writer를 Dispose합니다.
            writer.Configuration.CloseStream = false;

            try
            {
                writer.Write();
                dxfBytes = output.ToArray();
            }
            finally
            {
                writer.Dispose();
            }
        }

        if (dxfBytes.Length <= 0)
            throw new InvalidOperationException("DXF 파일이 생성되지 않았습니다.");

        log?.Invoke($"DXF 생성 완료: {dxfBytes.Length:N0} bytes · 재읽기 검증 중...");

        using var verifyStream = new MemoryStream(dxfBytes, writable: false);
        CadDocument dxfDoc;
        using (var dxfReader = new DxfReader(verifyStream))
        {
            dxfDoc = dxfReader.Read() ?? throw new InvalidOperationException("생성된 DXF를 다시 읽어 검증하지 못했습니다.");
        }

        var after = GetDocStats(dxfDoc);
        var diffs = CompareStats(before, after);

        FontUsageResult? fontUsage = null;
        if (options.FontMode != FontMode.None && fontResult is { TotalApplied: > 0 })
        {
            fontUsage = GetWqyUnicodeUsage(dxfDoc);
            if (!fontUsage.StyleExists)
                diffs.Add("wqy-unicode 스타일이 DXF에 저장되지 않음");
            else if (fontUsage.TextEntities == 0 && fontUsage.DimensionStyles == 0)
                diffs.Add("wqy-unicode 문자 스타일 적용 0건");
            else
                log?.Invoke($"글꼴 재검증: wqy-unicode 스타일 정상 (문자 {fontUsage.TextEntities}, 치수스타일 {fontUsage.DimensionStyles})");
        }

        var baseName = Path.GetFileNameWithoutExtension(file.Name);
        return new ConversionResult
        {
            SourceName = file.Name,
            OutputName = $"{baseName}.dxf",
            DxfBytes = dxfBytes,
            NeedsReview = diffs.Count > 0,
            Differences = diffs,
            Before = before,
            After = after,
            FontResult = fontResult,
            FontUsage = fontUsage
        };
    }

    public static byte[] CreateZip(IReadOnlyCollection<ConversionResult> results)
    {
        using var zipStream = new MemoryStream();
        using (var archive = new System.IO.Compression.ZipArchive(zipStream, System.IO.Compression.ZipArchiveMode.Create, leaveOpen: true))
        {
            var usedNames = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            foreach (var result in results)
            {
                var name = GetUniqueName(result.OutputName, usedNames);
                var entry = archive.CreateEntry(name, System.IO.Compression.CompressionLevel.Fastest);
                using var entryStream = entry.Open();
                entryStream.Write(result.DxfBytes, 0, result.DxfBytes.Length);
            }
        }
        return zipStream.ToArray();
    }

    private static string GetUniqueName(string fileName, HashSet<string> used)
    {
        if (used.Add(fileName)) return fileName;
        var stem = Path.GetFileNameWithoutExtension(fileName);
        var ext = Path.GetExtension(fileName);
        for (var i = 2; ; i++)
        {
            var candidate = $"{stem}_변환_{i}{ext}";
            if (used.Add(candidate)) return candidate;
        }
    }

    public static CadStats GetDocStats(CadDocument doc)
    {
        var total = 0; var line = 0; var polyline = 0; var arc = 0; var circle = 0;
        var insert = 0; var text = 0; var dimension = 0; var hatch = 0; var other = 0;

        IEnumerable entities = doc.Entities;
        try
        {
            var blocks = doc.BlockRecords.Cast<object>().ToList();
            if (blocks.Count > 0)
                entities = blocks.SelectMany(GetEntitiesFromBlock).ToList();
        }
        catch { }

        foreach (var entity in entities)
        {
            if (entity is null) continue;
            total++;
            var name = entity.GetType().Name;
            if (name == "Line") line++;
            else if (name.Contains("Polyline", StringComparison.OrdinalIgnoreCase)) polyline++;
            else if (name == "Arc") arc++;
            else if (name == "Circle") circle++;
            else if (name == "Insert") insert++;
            else if (name is "TextEntity" or "MText" or "AttributeEntity" or "AttributeDefinition") text++;
            else if (name.StartsWith("Dimension", StringComparison.Ordinal)) dimension++;
            else if (name == "Hatch") hatch++;
            else other++;
        }

        return new CadStats(total, line, polyline, arc, circle, insert, text, dimension, hatch, other,
            doc.Layers?.Count ?? 0, doc.BlockRecords?.Count ?? 0);
    }

    private static IEnumerable<object> GetEntitiesFromBlock(object blockRecord)
    {
        var prop = blockRecord.GetType().GetProperty("Entities", BindingFlags.Public | BindingFlags.Instance);
        if (prop?.GetValue(blockRecord) is not IEnumerable items) yield break;
        foreach (var item in items)
            if (item is not null) yield return item;
    }

    public static List<string> CompareStats(CadStats before, CadStats after)
    {
        var diffs = new List<string>();
        Compare("Total", before.Total, after.Total);
        Compare("Line", before.Line, after.Line);
        Compare("Polyline", before.Polyline, after.Polyline);
        Compare("Arc", before.Arc, after.Arc);
        Compare("Circle", before.Circle, after.Circle);
        Compare("Insert", before.Insert, after.Insert);
        Compare("Text", before.Text, after.Text);
        return diffs;

        void Compare(string name, int a, int b)
        {
            if (a != b) diffs.Add($"{name} {a} -> {b}");
        }
    }

    private static TextStyle GetWqyUnicodeStyle(CadDocument doc)
    {
        TextStyle style;
        if (doc.TextStyles.Contains("wqy-unicode"))
            style = doc.TextStyles["wqy-unicode"];
        else
            style = doc.TextStyles.TryAdd(new TextStyle("wqy-unicode"));

        style.Filename = "wqy-unicode.lff";
        style.BigFontFilename = string.Empty;
        return style;
    }

    private static bool ContainsHangul(string? text) => !string.IsNullOrEmpty(text) && HangulRegex.IsMatch(text);

    private static string GetCadTextValue(object? entity)
    {
        if (entity is null) return string.Empty;
        try
        {
            var p = entity.GetType().GetProperty("Value", BindingFlags.Public | BindingFlags.Instance);
            return p?.GetValue(entity)?.ToString() ?? string.Empty;
        }
        catch { return string.Empty; }
    }

    private static bool EntityContainsHangul(object? entity)
    {
        if (entity is null) return false;
        if (ContainsHangul(GetCadTextValue(entity))) return true;
        try
        {
            var mtext = entity.GetType().GetProperty("MText", BindingFlags.Public | BindingFlags.Instance)?.GetValue(entity);
            return mtext is not null && ContainsHangul(GetCadTextValue(mtext));
        }
        catch { return false; }
    }

    private static FontApplyResult SetWqyUnicodeStyle(CadDocument doc, FontMode mode)
    {
        var koreanOnly = mode == FontMode.KoreanOnly;
        TextStyle? wqy = null;
        var textCount = 0;
        var attributeCount = 0;
        var dimensionStyleCount = 0;

        IEnumerable<object> entities;
        try { entities = doc.BlockRecords.Cast<object>().SelectMany(GetEntitiesFromBlock).ToList(); }
        catch { entities = doc.Entities.Cast<object>().ToList(); }

        foreach (var entity in entities)
        {
            var shouldApply = !koreanOnly || EntityContainsHangul(entity);
            if (shouldApply && TrySetTextStyle(entity, ref wqy, doc)) textCount++;

            var attrs = entity.GetType().GetProperty("Attributes", BindingFlags.Public | BindingFlags.Instance)?.GetValue(entity) as IEnumerable;
            if (attrs is null) continue;
            foreach (var attr in attrs)
            {
                if (attr is null) continue;
                var attrHasHangul = EntityContainsHangul(attr);
                if ((!koreanOnly || attrHasHangul) && TrySetTextStyle(attr, ref wqy, doc)) attributeCount++;

                var mtext = attr.GetType().GetProperty("MText", BindingFlags.Public | BindingFlags.Instance)?.GetValue(attr);
                if (mtext is not null && (!koreanOnly || ContainsHangul(GetCadTextValue(mtext))) && TrySetTextStyle(mtext, ref wqy, doc))
                    attributeCount++;
            }
        }

        if (!koreanOnly)
        {
            foreach (var dimStyle in doc.DimensionStyles.Cast<object>())
            {
                if (TrySetTextStyle(dimStyle, ref wqy, doc)) dimensionStyleCount++;
            }
        }

        return new FontApplyResult(textCount, attributeCount, dimensionStyleCount, mode);
    }

    private static bool TrySetTextStyle(object target, ref TextStyle? wqy, CadDocument doc)
    {
        try
        {
            var prop = target.GetType().GetProperty("Style", BindingFlags.Public | BindingFlags.Instance);
            if (prop is null || !prop.CanWrite || !typeof(TextStyle).IsAssignableFrom(prop.PropertyType)) return false;
            wqy ??= GetWqyUnicodeStyle(doc);
            prop.SetValue(target, wqy);
            return true;
        }
        catch { return false; }
    }

    private static FontUsageResult GetWqyUnicodeUsage(CadDocument doc)
    {
        var styleExists = doc.TextStyles.Contains("wqy-unicode");
        var textCount = 0;
        var dimensionStyleCount = 0;

        IEnumerable<object> entities;
        try { entities = doc.BlockRecords.Cast<object>().SelectMany(GetEntitiesFromBlock).ToList(); }
        catch { entities = doc.Entities.Cast<object>().ToList(); }

        foreach (var entity in entities)
        {
            if (UsesWqyStyle(entity)) textCount++;
            var attrs = entity.GetType().GetProperty("Attributes", BindingFlags.Public | BindingFlags.Instance)?.GetValue(entity) as IEnumerable;
            if (attrs is null) continue;
            foreach (var attr in attrs)
                if (attr is not null && UsesWqyStyle(attr)) textCount++;
        }

        foreach (var dimStyle in doc.DimensionStyles.Cast<object>())
            if (UsesWqyStyle(dimStyle)) dimensionStyleCount++;

        return new FontUsageResult(styleExists, textCount, dimensionStyleCount);
    }

    private static bool UsesWqyStyle(object target)
    {
        try
        {
            var prop = target.GetType().GetProperty("Style", BindingFlags.Public | BindingFlags.Instance);
            return prop?.GetValue(target) is TextStyle style && style.Name == "wqy-unicode";
        }
        catch { return false; }
    }
}
