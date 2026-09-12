namespace DWG2DXF.Web.Models;

public enum FontMode
{
    None,
    All,
    KoreanOnly
}

public enum OutputVersionMode
{
    AutoCad2010,
    KeepOriginal
}

public sealed class QueuedDwgFile
{
    public required string Id { get; init; }
    public required string Name { get; init; }
    public required long Size { get; init; }
    public required Microsoft.AspNetCore.Components.Forms.IBrowserFile BrowserFile { get; init; }
    public string? ValidationError { get; set; }
    public string? Header { get; set; }
    public string Status { get; set; } = "대기";
}

public sealed class ConversionOptions
{
    public FontMode FontMode { get; set; } = FontMode.All;
    public OutputVersionMode OutputVersion { get; set; } = OutputVersionMode.AutoCad2010;
}

public sealed record CadStats(
    int Total,
    int Line,
    int Polyline,
    int Arc,
    int Circle,
    int Insert,
    int Text,
    int Dimension,
    int Hatch,
    int Other,
    int Layers,
    int Blocks);

public sealed record FontApplyResult(
    int TextEntities,
    int Attributes,
    int DimensionStyles,
    FontMode Mode)
{
    public int TotalApplied => TextEntities + Attributes + DimensionStyles;
}

public sealed record FontUsageResult(bool StyleExists, int TextEntities, int DimensionStyles);

public sealed class ConversionResult
{
    public required string SourceName { get; init; }
    public required string OutputName { get; init; }
    public required byte[] DxfBytes { get; init; }
    public required bool NeedsReview { get; init; }
    public required IReadOnlyList<string> Differences { get; init; }
    public required CadStats Before { get; init; }
    public required CadStats After { get; init; }
    public FontApplyResult? FontResult { get; init; }
    public FontUsageResult? FontUsage { get; init; }
}
