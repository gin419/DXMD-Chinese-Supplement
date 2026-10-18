param(
    [string]$GameRoot = 'G:\SteamLibrary\steamapps\common\Deus Ex Mankind Divided',
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$exe = Join-Path $GameRoot 'retail\DXMD.exe'
if (-not (Test-Path -LiteralPath $exe)) {
    throw "找不到游戏执行文件：$exe"
}

$v = (Get-Item -LiteralPath $exe).VersionInfo
$report = [ordered]@{
    game_root = $GameRoot
    executable = $exe
    file_version = $v.FileVersion
    product_version = $v.ProductVersion
    strings_file = (Join-Path $ProjectRoot 'translation\strings.json')
    missing_file = (Join-Path $ProjectRoot 'translation\missing.json')
    generated_at = (Get-Date).ToString('o')
}
$report | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $ProjectRoot 'audit.json') -Encoding UTF8
$report | ConvertTo-Json
