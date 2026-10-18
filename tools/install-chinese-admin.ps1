param(
    [string]$GameRetail = 'G:\SteamLibrary\steamapps\common\Deus Ex Mankind Divided\retail',
    [switch]$AllowTextOnly
)

$ErrorActionPreference = 'Stop'
$project = Split-Path -Parent $PSScriptRoot
$package = Join-Path $project 'dist\DXMD-Chinese-v1.19-text-supplement\retail'
$required = @('DXMD_Mod.ini', 'strings.json', 'font_ui_cn.swf')

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Please run PowerShell as Administrator, then run this script again.'
}
if (-not (Test-Path -LiteralPath $GameRetail)) { throw "Game directory not found: $GameRetail" }
foreach ($name in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $package $name))) { throw "Package file missing: $name" }
}

$bink = Join-Path $GameRetail 'bink2w64.dll'
$originalHash = '2BCAD8CE34EDA873133A1AF433EE87731AD92FD87A09469C846E5BF5FCE4C225'
if ((Test-Path -LiteralPath $bink) -and -not $AllowTextOnly) {
    $sha = [Security.Cryptography.SHA256]::Create()
    $hash = ([BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($bink)))).Replace('-', '')
    $sha.Dispose()
    if ($hash -eq $originalHash) {
        throw 'The current bink2w64.dll is the original game DLL. Install the modern DXMD-Translations bink2w64.dll first, or rerun with -AllowTextOnly.'
    }
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup = Join-Path $GameRetail ("DXMD-Chinese-backup-$stamp")
New-Item -ItemType Directory -Path $backup -Force | Out-Null
foreach ($name in $required) {
    $target = Join-Path $GameRetail $name
    if (Test-Path -LiteralPath $target) { Copy-Item -LiteralPath $target -Destination (Join-Path $backup $name) -Force }
    Copy-Item -LiteralPath (Join-Path $package $name) -Destination $target -Force
}
Write-Output "Installed Chinese text/font/config files into $GameRetail"
Write-Output "Backup: $backup"
if ($AllowTextOnly) { Write-Warning 'Text-only mode was used; without the modern framework DLL the game will not load these files.' }
