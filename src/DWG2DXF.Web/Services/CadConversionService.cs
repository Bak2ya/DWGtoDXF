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

    // Common CJK ranges used in Korean/Japanese/Chinese CAD text.
    // Supplementary-plane CJK extensions are intentionally outside this conservative BMP matcher.
    private static readonly Regex CjkRegex = new(
        "[\\u1100-\\u11FF\\u3130-\\u318F\\uA960-\\uA97F\\uAC00-\\uD7AF\\uD7B0-\\uD7FF" +
        "\\u3040-\\u309F\\u30A0-\\u30FF\\u31F0-\\u31FF\\u3400-\\u4DBF\\u4E00-\\u9FFF" +
        "\\uF900-\\uFAFF\\uFF65-\\uFF9F]",
        RegexOptions.Compiled);

    private readonly LocalizationService _l;

    public CadConversionService(LocalizationService localization)
    {
        _l = localization;
    }

    public async Task<FileValidationResult> ValidateBrowserFileAsync(
        Microsoft.AspNetCore.Components.Forms.IBrowserFile file,
        CancellationToken cancellationToken = default)
    {
        if (!file.Name.EndsWith(".dwg", StringComparison.OrdinalIgnoreCase))
            return new FileValidationResult(null, "validation.notDwg");

        if (file.Size < 6)
            return new FileValidationResult(null, "validation.invalidHeader");

        if (file.Size > DefaultMaxFileSize)
            return new FileValidationResult(
                null,
                "validation.tooLarge",
                new object[] { DefaultMaxFileSize / 1024 / 1024 });

        await using var stream = file.OpenReadStream(DefaultMaxFileSize, cancellationToken);
        var buffer = new byte[6];
        var read = await stream.ReadAsync(buffer.AsMemory(0, 6), cancellationToken);

        if (read < 6)
            return new FileValidationResult(null, "validation.invalidHeader");

        var header = Encoding.ASCII.GetString(buffer);

        if (!Regex.IsMatch(header, "^AC10[0-9]{2}$"))
            return new FileValidationResult(header, "validation.unrecognized");

        if (header is "AC1009" or "AC1012")
            return new FileValidationResult(
                header,
                "validation.oldVersion",
                new object[] { header });

        return new FileValidationResult(header);
    }

    public async Task<ConversionResult> ConvertAsync(
        Microsoft.AspNetCore.Components.Forms.IBrowserFile file,
        ConversionOptions options,
        Action<string>? log = null,
        Action<int, string>? progress = null,
        CancellationToken cancellationToken = default)
    {
        progress?.Invoke(3, "progress.loading");
        log?.Invoke(_l.T("log.reading", file.Name));
        await Task.Delay(16, cancellationToken);

        await using var browserStream = file.OpenReadStream(DefaultMaxFileSize, cancellationToken);
        using var input = new MemoryStream((int)Math.Min(file.Size, int.MaxValue));
        await browserStream.CopyToAsync(input, cancellationToken);
        input.Position = 0;

        progress?.Invoke(18, "progress.analyzing");
        log?.Invoke(_l.Get("log.analyzing"));
        await Task.Delay(16, cancellationToken);

        CadDocument doc;
        using (var reader = new DwgReader(input))
        {
            doc = reader.Read() ?? throw new InvalidOperationException(_l.Get("error.readDwg"));
        }

        progress?.Invoke(48, "progress.inspecting");
        await Task.Delay(16, cancellationToken);

        var before = GetDocStats(doc);

        progress?.Invoke(55, "progress.output");
        await Task.Delay(16, cancellationToken);

        if (options.OutputVersion == OutputVersionMode.AutoCad2010)
        {
            doc.Header.Version = ACadVersion.AC1024;
            log?.Invoke(_l.Get("log.output2010"));
        }
        else
        {
            log?.Invoke(_l.T("log.outputOriginal", doc.Header.Version));
        }

        progress?.Invoke(
            62,
            options.FontMode == FontMode.None ? "progress.fontCheck" : "progress.fontConvert");
        await Task.Delay(16, cancellationToken);

        FontApplyResult? fontResult = null;

        switch (options.FontMode)
        {
            case FontMode.All:
                fontResult = SetWqyUnicodeStyle(doc, FontMode.All);
                log?.Invoke(_l.T(
                    "log.fontAll",
                    fontResult.TextEntities,
                    fontResult.Attributes,
                    fontResult.DimensionStyles));
                break;

            case FontMode.CjkOnly:
                fontResult = SetWqyUnicodeStyle(doc, FontMode.CjkOnly);
                log?.Invoke(fontResult.TotalApplied > 0
                    ? _l.T("log.fontCjk", fontResult.TextEntities, fontResult.Attributes)
                    : _l.Get("log.fontCjkNone"));
                break;

            default:
                log?.Invoke(_l.Get("log.fontNone"));
                break;
        }

        progress?.Invoke(75, "progress.generating");
        log?.Invoke(_l.Get("log.generating"));
        await Task.Delay(16, cancellationToken);

        byte[] dxfBytes;

        using (var output = new MemoryStream())
        {
            var writer = new DxfWriter(output, doc, binary: false);
            writer.Configuration.CloseStream = false;

            try
            {
                writer.Write();

                // DxfWriter.Dispose() closes the underlying stream in ACadSharp 3.6.51.
                // Copy the bytes before disposing the writer.
                dxfBytes = output.ToArray();
            }
            finally
            {
                writer.Dispose();
            }
        }

        if (dxfBytes.Length <= 0)
            throw new InvalidOperationException(_l.Get("error.emptyDxf"));

        log?.Invoke(_l.T("log.generated", dxfBytes.Length));
        progress?.Invoke(88, "progress.verifying");
        await Task.Delay(16, cancellationToken);

        using var verifyStream = new MemoryStream(dxfBytes, writable: false);

        CadDocument dxfDoc;
        using (var dxfReader = new DxfReader(verifyStream))
        {
            dxfDoc = dxfReader.Read() ?? throw new InvalidOperationException(_l.Get("error.verifyDxf"));
        }

        progress?.Invoke(95, "progress.summarizing");
        await Task.Delay(16, cancellationToken);

        var after = GetDocStats(dxfDoc);
        var diffs = CompareStats(before, after);

        FontUsageResult? fontUsage = null;

        if (options.FontMode != FontMode.None && fontResult is { TotalApplied: > 0 })
        {
            fontUsage = GetWqyUnicodeUsage(dxfDoc);

            if (!fontUsage.StyleExists)
                diffs.Add(_l.Get("difference.fontStyleMissing"));
            else if (fontUsage.TextEntities == 0 && fontUsage.DimensionStyles == 0)
                diffs.Add(_l.Get("difference.fontUsageZero"));
            else
                log?.Invoke(_l.T(
                    "log.fontVerified",
                    fontUsage.TextEntities,
                    fontUsage.DimensionStyles));
        }

        progress?.Invoke(100, "progress.done");

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

        using (var archive = new System.IO.Compression.ZipArchive(
            zipStream,
            System.IO.Compression.ZipArchiveMode.Create,
            leaveOpen: true))
        {
            var usedNames = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            foreach (var result in results)
            {
                var name = GetUniqueName(result.OutputName, usedNames);
                var entry = archive.CreateEntry(
                    name,
                    System.IO.Compression.CompressionLevel.Fastest);

                using var entryStream = entry.Open();
                entryStream.Write(result.DxfBytes, 0, result.DxfBytes.Length);
            }
        }

        return zipStream.ToArray();
    }

    private static string GetUniqueName(string fileName, HashSet<string> used)
    {
        if (used.Add(fileName))
            return fileName;

        var stem = Path.GetFileNameWithoutExtension(fileName);
        var ext = Path.GetExtension(fileName);

        for (var i = 2; ; i++)
        {
            var candidate = $"{stem}_converted_{i}{ext}";
            if (used.Add(candidate))
                return candidate;
        }
    }

    public static CadStats GetDocStats(CadDocument doc)
    {
        var total = 0;
        var line = 0;
        var polyline = 0;
        var arc = 0;
        var circle = 0;
        var insert = 0;
        var text = 0;
        var dimension = 0;
        var hatch = 0;
        var other = 0;

        IEnumerable entities = doc.Entities;

        try
        {
            var blocks = doc.BlockRecords.Cast<object>().ToList();
            if (blocks.Count > 0)
                entities = blocks.SelectMany(GetEntitiesFromBlock).ToList();
        }
        catch
        {
            // Fall back to document entities if block traversal is unavailable.
        }

        foreach (var entity in entities)
        {
            if (entity is null)
                continue;

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

        return new CadStats(
            total,
            line,
            polyline,
            arc,
            circle,
            insert,
            text,
            dimension,
            hatch,
            other,
            doc.Layers?.Count ?? 0,
            doc.BlockRecords?.Count ?? 0);
    }

    private static IEnumerable<object> GetEntitiesFromBlock(object blockRecord)
    {
        var prop = blockRecord.GetType().GetProperty(
            "Entities",
            BindingFlags.Public | BindingFlags.Instance);

        if (prop?.GetValue(blockRecord) is not IEnumerable items)
            yield break;

        foreach (var item in items)
        {
            if (item is not null)
                yield return item;
        }
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
            if (a != b)
                diffs.Add($"{name} {a} -> {b}");
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

    private static bool ContainsCjk(string? text) =>
        !string.IsNullOrEmpty(text) && CjkRegex.IsMatch(text);

    private static string GetCadTextValue(object? entity)
    {
        if (entity is null)
            return string.Empty;

        try
        {
            var property = entity.GetType().GetProperty(
                "Value",
                BindingFlags.Public | BindingFlags.Instance);

            return property?.GetValue(entity)?.ToString() ?? string.Empty;
        }
        catch
        {
            return string.Empty;
        }
    }

    private static bool EntityContainsCjk(object? entity)
    {
        if (entity is null)
            return false;

        if (ContainsCjk(GetCadTextValue(entity)))
            return true;

        try
        {
            var mtext = entity.GetType()
                .GetProperty("MText", BindingFlags.Public | BindingFlags.Instance)
                ?.GetValue(entity);

            return mtext is not null && ContainsCjk(GetCadTextValue(mtext));
        }
        catch
        {
            return false;
        }
    }

    private static FontApplyResult SetWqyUnicodeStyle(CadDocument doc, FontMode mode)
    {
        var cjkOnly = mode == FontMode.CjkOnly;

        TextStyle? wqy = null;
        var textCount = 0;
        var attributeCount = 0;
        var dimensionStyleCount = 0;

        IEnumerable<object> entities;

        try
        {
            entities = doc.BlockRecords
                .Cast<object>()
                .SelectMany(GetEntitiesFromBlock)
                .ToList();
        }
        catch
        {
            entities = doc.Entities.Cast<object>().ToList();
        }

        foreach (var entity in entities)
        {
            var shouldApply = !cjkOnly || EntityContainsCjk(entity);

            if (shouldApply && TrySetTextStyle(entity, ref wqy, doc))
                textCount++;

            var attrs = entity.GetType()
                .GetProperty("Attributes", BindingFlags.Public | BindingFlags.Instance)
                ?.GetValue(entity) as IEnumerable;

            if (attrs is null)
                continue;

            foreach (var attr in attrs)
            {
                if (attr is null)
                    continue;

                var attrHasCjk = EntityContainsCjk(attr);

                if ((!cjkOnly || attrHasCjk) && TrySetTextStyle(attr, ref wqy, doc))
                    attributeCount++;

                var mtext = attr.GetType()
                    .GetProperty("MText", BindingFlags.Public | BindingFlags.Instance)
                    ?.GetValue(attr);

                if (mtext is not null &&
                    (!cjkOnly || ContainsCjk(GetCadTextValue(mtext))) &&
                    TrySetTextStyle(mtext, ref wqy, doc))
                {
                    attributeCount++;
                }
            }
        }

        // In CJK-only mode, shared DimensionStyle objects are intentionally left unchanged.
        // Changing a shared dimension style could alter numeric/Latin-only dimensions.
        if (!cjkOnly)
        {
            foreach (var dimStyle in doc.DimensionStyles.Cast<object>())
            {
                if (TrySetTextStyle(dimStyle, ref wqy, doc))
                    dimensionStyleCount++;
            }
        }

        return new FontApplyResult(
            textCount,
            attributeCount,
            dimensionStyleCount,
            mode);
    }

    private static bool TrySetTextStyle(
        object target,
        ref TextStyle? wqy,
        CadDocument doc)
    {
        try
        {
            var prop = target.GetType().GetProperty(
                "Style",
                BindingFlags.Public | BindingFlags.Instance);

            if (prop is null ||
                !prop.CanWrite ||
                !typeof(TextStyle).IsAssignableFrom(prop.PropertyType))
            {
                return false;
            }

            wqy ??= GetWqyUnicodeStyle(doc);
            prop.SetValue(target, wqy);
            return true;
        }
        catch
        {
            return false;
        }
    }

    private static FontUsageResult GetWqyUnicodeUsage(CadDocument doc)
    {
        var styleExists = doc.TextStyles.Contains("wqy-unicode");
        var textCount = 0;
        var dimensionStyleCount = 0;

        IEnumerable<object> entities;

        try
        {
            entities = doc.BlockRecords
                .Cast<object>()
                .SelectMany(GetEntitiesFromBlock)
                .ToList();
        }
        catch
        {
            entities = doc.Entities.Cast<object>().ToList();
        }

        foreach (var entity in entities)
        {
            if (UsesWqyStyle(entity))
                textCount++;

            var attrs = entity.GetType()
                .GetProperty("Attributes", BindingFlags.Public | BindingFlags.Instance)
                ?.GetValue(entity) as IEnumerable;

            if (attrs is null)
                continue;

            foreach (var attr in attrs)
            {
                if (attr is not null && UsesWqyStyle(attr))
                    textCount++;
            }
        }

        foreach (var dimStyle in doc.DimensionStyles.Cast<object>())
        {
            if (UsesWqyStyle(dimStyle))
                dimensionStyleCount++;
        }

        return new FontUsageResult(
            styleExists,
            textCount,
            dimensionStyleCount);
    }

    private static bool UsesWqyStyle(object target)
    {
        try
        {
            var prop = target.GetType().GetProperty(
                "Style",
                BindingFlags.Public | BindingFlags.Instance);

            return prop?.GetValue(target) is TextStyle style &&
                   style.Name == "wqy-unicode";
        }
        catch
        {
            return false;
        }
    }
}
