param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$stage = Join-Path $ProjectRoot 'dist\DXMD-Chinese-Standalone'
$payload = Join-Path $stage 'payload'
$installer = Join-Path $ProjectRoot 'installer'
$sourceStrings = Join-Path $ProjectRoot 'translation\strings.json'
$sourceFont = Join-Path $ProjectRoot 'work\chinese-package\font_ui_cn.swf'
$sourceConfig = Join-Path $ProjectRoot 'dist\DXMD-Chinese-v1.19-text-supplement\retail\DXMD_Mod.ini'
$sourceBink = 'C:\Users\Gin\Downloads\2026-07-31_tr\bink2w64.dll'

foreach ($path in @($sourceStrings, $sourceFont, $sourceConfig, $sourceBink)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing source file: $path" }
}
New-Item -ItemType Directory -Path $stage -Force | Out-Null
New-Item -ItemType Directory -Path $payload -Force | Out-Null
foreach ($file in Get-ChildItem -LiteralPath $installer -File) {
    Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $stage $file.Name) -Force
}
Copy-Item -LiteralPath $sourceStrings -Destination (Join-Path $payload 'strings.json') -Force
Copy-Item -LiteralPath $sourceFont -Destination (Join-Path $payload 'font_ui_cn.swf') -Force
Copy-Item -LiteralPath $sourceConfig -Destination (Join-Path $payload 'DXMD_Mod.ini') -Force
Copy-Item -LiteralPath $sourceBink -Destination (Join-Path $payload 'bink2w64.dll') -Force

$sha = [Security.Cryptography.SHA256]::Create()
$manifest = foreach ($file in Get-ChildItem -LiteralPath $stage -Recurse -File | Where-Object { $_.Name -notin @('manifest.json') }) {
    [ordered]@{
        file = $file.FullName.Substring($stage.Length + 1)
        bytes = $file.Length
        sha256 = ([BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($file.FullName)))).Replace('-', '')
    }
}
$sha.Dispose()
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $stage 'manifest.json') -Encoding UTF8

$archive = Join-Path $ProjectRoot 'dist\DXMD-Chinese-Standalone-v1.19.zip'
if (Test-Path -LiteralPath $archive) { Remove-Item -LiteralPath $archive -Force }
tar -a -c -f $archive -C (Join-Path $ProjectRoot 'dist') 'DXMD-Chinese-Standalone'
Write-Output "Built folder: $stage"
Write-Output "Built archive: $archive"
