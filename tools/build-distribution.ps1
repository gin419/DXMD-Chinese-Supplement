param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$source = Join-Path $ProjectRoot 'work\chinese-package'
$strings = Join-Path $ProjectRoot 'translation\strings.json'
$font = Join-Path $source 'font_ui_cn.swf'
$legacyDll = Join-Path $source 'version.dll'
foreach ($path in @($strings, $font, $legacyDll)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing imported package file: $path" }
}

$dist = Join-Path $ProjectRoot 'dist'
$textRoot = Join-Path $dist 'DXMD-Chinese-v1.19-text-supplement'
$legacyRoot = Join-Path $dist 'DXMD-Chinese-v1.19-legacy'
foreach ($root in @($textRoot, $legacyRoot)) {
    New-Item -ItemType Directory -Path (Join-Path $root 'retail') -Force | Out-Null
}

foreach ($root in @($textRoot, $legacyRoot)) {
    $retail = Join-Path $root 'retail'
    Copy-Item -LiteralPath $strings -Destination (Join-Path $retail 'strings.json') -Force
    Copy-Item -LiteralPath $font -Destination (Join-Path $retail 'font_ui_cn.swf') -Force
    @'
; DXMD Chinese text supplement for Steam v1.19
[DLL]
Chain=
Debug=0
LogFile=.\DXMD_Mod.log

[Language]
StringsJSON=.\strings.json
UIFont=.\font_ui_cn.swf
EnableTranslation=1
CutsceneBugFixWarning=0

[Game]
DebugResourceIDMapping=0
'@ | Set-Content -LiteralPath (Join-Path $retail 'DXMD_Mod.ini') -Encoding UTF8
}

Copy-Item -LiteralPath $legacyDll -Destination (Join-Path $legacyRoot 'retail\version.dll') -Force

$sha = [Security.Cryptography.SHA256]::Create()
$manifest = foreach ($file in Get-ChildItem -LiteralPath $dist -Recurse -File | Where-Object { $_.Name -ne 'manifest.json' }) {
    $bytes = [IO.File]::ReadAllBytes($file.FullName)
    $digest = ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '')
    [ordered]@{
        file = $file.FullName.Substring($dist.Length + 1)
        bytes = $file.Length
        sha256 = $digest
    }
}
$sha.Dispose()
$manifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $dist 'manifest.json') -Encoding UTF8
Write-Output "Built distributions under $dist"
