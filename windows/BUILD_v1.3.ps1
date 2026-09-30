# DWG2DXF v1.3 build script
# Builds a distributable Windows EXE using the Microsoft C# compiler included with .NET Framework.

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Src = Join-Path $Root 'src'
$Payload = Join-Path $Src 'payload'
$Lib = Join-Path $Payload 'lib'
$Dist = Join-Path $Root 'dist'
$OutExe = Join-Path $Dist 'DWG2DXF_v1.3.exe'

function Write-Title([string]$text) {
    Write-Host ''
    Write-Host ('=== ' + $text + ' ===') -ForegroundColor Cyan
}

function Get-CscPath {
    $candidates = @(
        (Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'),
        (Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe')
    )
    foreach ($p in $candidates) {
        if (Test-Path -LiteralPath $p -PathType Leaf) { return $p }
    }
    return $null
}

function Test-NetFramework48 {
    try {
        $release = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -Name Release -ErrorAction Stop).Release
        return ([int]$release -ge 528040)
    } catch {
        return $false
    }
}

function Get-NugetDll {
    param(
        [Parameter(Mandatory=$true)][string]$Id,
        [Parameter(Mandatory=$true)][string]$Version,
        [Parameter(Mandatory=$true)][string]$RelativeDll,
        [Parameter(Mandatory=$true)][string]$DllName
    )

    $target = Join-Path $Lib $DllName
    if (Test-Path -LiteralPath $target -PathType Leaf) {
        Write-Host "[OK] cached: $DllName"
        return
    }

    $tmpBase = Join-Path ([IO.Path]::GetTempPath()) ('DWG2DXF_BUILD_' + [guid]::NewGuid().ToString('N'))
    $zipPath = $tmpBase + '.zip'
    $extractPath = $tmpBase + '_x'
    $idLower = $Id.ToLowerInvariant()
    $verLower = $Version.ToLowerInvariant()
    $url = "https://api.nuget.org/v3-flatcontainer/$idLower/$verLower/$idLower.$verLower.nupkg"

    try {
        Write-Host "[GET] $Id $Version"
        Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $zipPath
        $sig = [System.IO.File]::ReadAllBytes($zipPath)
        if ($sig.Length -lt 4 -or $sig[0] -ne 0x50 -or $sig[1] -ne 0x4B) {
            throw "NuGet download was not a valid package file: $Id $Version"
        }
        Expand-Archive -LiteralPath $zipPath -DestinationPath $extractPath -Force

        $source = Join-Path $extractPath $RelativeDll
        if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
            $candidate = Get-ChildItem -LiteralPath $extractPath -Recurse -File -Filter $DllName -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -match '[\\/]lib[\\/]' } |
                Select-Object -First 1
            if ($null -eq $candidate) {
                throw "NuGet package does not contain $DllName : $Id $Version"
            }
            $source = $candidate.FullName
        }

        Copy-Item -LiteralPath $source -Destination $target -Force
        Write-Host "[OK] $DllName"
    }
    finally {
        Remove-Item -LiteralPath $zipPath -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $extractPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}


try {
    Write-Title 'DWG2DXF v1.3 Multilingual EXE Build'

    if (-not (Test-NetFramework48)) {
        throw '.NET Framework 4.8 or later is required on the build PC. Install it through Windows Update/Microsoft and run this build again.'
    }

    $csc = Get-CscPath
    if ([string]::IsNullOrWhiteSpace($csc)) {
        throw 'Microsoft C# compiler (csc.exe) was not found. Repair/install .NET Framework 4.8 and try again.'
    }

    if (-not (Test-Path -LiteralPath (Join-Path $Payload 'DWG2DXF.ps1'))) {
        throw 'src\payload\DWG2DXF.ps1 is missing.'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $Payload 'resources\app.ico'))) {
        throw 'src\payload\resources\app.ico is missing.'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $Payload 'resources\app_logo.png'))) {
        throw 'src\payload\resources\app_logo.png is missing.'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $Src 'app.ico'))) {
        throw 'src\app.ico is missing.'
    }

    New-Item -ItemType Directory -Path $Lib -Force | Out-Null
    New-Item -ItemType Directory -Path $Dist -Force | Out-Null

    Write-Title 'Checking bundled LibreCAD Unicode/CJK font'
    $fontPath = Join-Path $Payload 'resources\wqy-unicode.lff'
    if (-not (Test-Path -LiteralPath $fontPath -PathType Leaf)) {
        throw 'Bundled font is missing: src\payload\resources\wqy-unicode.lff'
    }
    $fontHeader = Get-Content -LiteralPath $fontPath -TotalCount 1 -Encoding UTF8
    if ($fontHeader -notmatch 'LibreCAD Font 1') {
        throw 'Bundled wqy-unicode.lff does not look like a valid LibreCAD font file.'
    }
    Write-Host '[OK] bundled: wqy-unicode.lff'

    Write-Title 'Preparing embedded conversion engine'
    Get-NugetDll -Id 'System.Runtime.CompilerServices.Unsafe' -Version '6.1.2' -RelativeDll 'lib\net462\System.Runtime.CompilerServices.Unsafe.dll' -DllName 'System.Runtime.CompilerServices.Unsafe.dll'
    Get-NugetDll -Id 'System.Buffers' -Version '4.6.1' -RelativeDll 'lib\net462\System.Buffers.dll' -DllName 'System.Buffers.dll'
    Get-NugetDll -Id 'System.Numerics.Vectors' -Version '4.6.1' -RelativeDll 'lib\net462\System.Numerics.Vectors.dll' -DllName 'System.Numerics.Vectors.dll'
    Get-NugetDll -Id 'System.Memory' -Version '4.6.3' -RelativeDll 'lib\net462\System.Memory.dll' -DllName 'System.Memory.dll'
    Get-NugetDll -Id 'ACadSharp' -Version '3.6.51' -RelativeDll 'lib\net48\ACadSharp.dll' -DllName 'ACadSharp.dll'

    $thirdParty = Join-Path $Payload 'THIRD_PARTY_NOTICES.txt'
    if (-not (Test-Path -LiteralPath $thirdParty)) {
        throw 'src\payload\THIRD_PARTY_NOTICES.txt is missing.'
    }

    Write-Title 'Compiling EXE'
    if (Test-Path -LiteralPath $OutExe) { Remove-Item -LiteralPath $OutExe -Force }

    $args = @(
        '/nologo',
        '/target:winexe',
        '/platform:anycpu',
        '/optimize+',
        '/debug-',
        ('/out:' + $OutExe),
        ('/win32manifest:' + (Join-Path $Src 'app.manifest')),
        ('/win32icon:' + (Join-Path $Src 'app.ico')),
        '/reference:System.dll',
        '/reference:System.Core.dll',
        '/reference:System.Windows.Forms.dll',
        ('/resource:' + (Join-Path $Payload 'DWG2DXF.ps1') + ',DWG2DXF.payload.DWG2DXF.ps1'),
        ('/resource:' + (Join-Path $Payload 'resources\wqy-unicode.lff') + ',HJU.payload.resources.wqy-unicode.lff'),
        ('/resource:' + (Join-Path $Payload 'resources\app.ico') + ',HJU.payload.resources.app.ico'),
        ('/resource:' + (Join-Path $Payload 'resources\app_logo.png') + ',HJU.payload.resources.app_logo.png'),
        ('/resource:' + (Join-Path $Lib 'ACadSharp.dll') + ',HJU.payload.lib.ACadSharp.dll'),
        ('/resource:' + (Join-Path $Lib 'System.Memory.dll') + ',HJU.payload.lib.System.Memory.dll'),
        ('/resource:' + (Join-Path $Lib 'System.Buffers.dll') + ',HJU.payload.lib.System.Buffers.dll'),
        ('/resource:' + (Join-Path $Lib 'System.Numerics.Vectors.dll') + ',HJU.payload.lib.System.Numerics.Vectors.dll'),
        ('/resource:' + (Join-Path $Lib 'System.Runtime.CompilerServices.Unsafe.dll') + ',HJU.payload.lib.System.Runtime.CompilerServices.Unsafe.dll'),
        ('/resource:' + (Join-Path $Payload 'licenses\Apache-2.0.txt') + ',HJU.payload.licenses.Apache-2.0.txt'),
        ('/resource:' + (Join-Path $Payload 'licenses\WQY_FONT_NOTICE.txt') + ',HJU.payload.licenses.WQY_FONT_NOTICE.txt'),
        ('/resource:' + $thirdParty + ',HJU.payload.THIRD_PARTY_NOTICES.txt'),
        (Join-Path $Src 'Launcher.cs')
    )

    & $csc @args
    if ($LASTEXITCODE -ne 0) {
        throw "C# compiler failed with exit code $LASTEXITCODE"
    }

    if (-not (Test-Path -LiteralPath $OutExe -PathType Leaf)) {
        throw 'EXE was not created.'
    }

    $hash = (Get-FileHash -LiteralPath $OutExe -Algorithm SHA256).Hash
    $sizeMb = [Math]::Round((Get-Item -LiteralPath $OutExe).Length / 1MB, 1)
    @(
        'DWG2DXF v1.3',
        ('File: ' + $OutExe),
        ('Size: ' + $sizeMb + ' MB'),
        ('SHA256: ' + $hash),
        '',
        'The built EXE contains ACadSharp 3.6.51, required .NET compatibility libraries, wqy-unicode.lff, the DWG2DXF application icon, and Korean/English/Japanese/Spanish UI.',
        'Target PCs do not need internet access for the conversion engine after this build.'
    ) | Set-Content -LiteralPath (Join-Path $Dist 'BUILD_INFO.txt') -Encoding UTF8

    Write-Title 'BUILD SUCCESS'
    Write-Host "Output: $OutExe" -ForegroundColor Green
    Write-Host "Size  : $sizeMb MB"
    Write-Host "SHA256: $hash"
    Write-Host ''
    Write-Host 'You can distribute the EXE in the dist folder.' -ForegroundColor Green
}
catch {
    Write-Host ''
    Write-Host ('BUILD FAILED: ' + $_.Exception.Message) -ForegroundColor Red
    Write-Host ''
    exit 1
}
