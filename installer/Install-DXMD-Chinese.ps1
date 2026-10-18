param(
    [string]$GameRetail = ''
)

$ErrorActionPreference = 'Stop'
$PackageRoot = Split-Path -Parent $PSCommandPath
$PayloadRoot = Join-Path $PackageRoot 'payload'
$TargetNames = @('bink2w64.dll', 'DXMD_Mod.ini', 'strings.json', 'font_ui_cn.swf')

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    $argString = '-NoProfile -ExecutionPolicy Bypass -File "' + $PSCommandPath + '"'
    if ($GameRetail) { $argString += ' -GameRetail "' + $GameRetail + '"' }
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $argString
    exit 0
}

function Get-SteamRoots {
    $roots = New-Object System.Collections.Generic.List[string]
    foreach ($key in @('HKCU:\Software\Valve\Steam', 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam', 'HKLM:\SOFTWARE\Valve\Steam')) {
        try {
            $p = (Get-ItemProperty -LiteralPath $key -ErrorAction Stop).SteamPath
            if ($p) { $roots.Add($p) }
        } catch {}
    }
    $vdfs = @()
    foreach ($root in $roots) { $vdfs += Join-Path $root 'steamapps\libraryfolders.vdf' }
    foreach ($vdf in $vdfs) {
        if (Test-Path -LiteralPath $vdf) {
            foreach ($line in Get-Content -LiteralPath $vdf) {
                if ($line -match '"path"\s+"([^"]+)"') { $roots.Add($matches[1].Replace('\\', '\')) }
            }
        }
    }
    return @($roots | Select-Object -Unique)
}

function Find-GameRetail {
    $candidates = New-Object System.Collections.Generic.List[string]
    foreach ($root in Get-SteamRoots) {
        $p = Join-Path $root 'steamapps\common\Deus Ex Mankind Divided\retail'
        if (Test-Path -LiteralPath (Join-Path $p 'DXMD.exe')) { $candidates.Add($p) }
    }
    if ($candidates.Count -eq 1) { return $candidates[0] }
    if ($candidates.Count -gt 1) {
        Write-Host 'Multiple Deus Ex installations found:'
        for ($i = 0; $i -lt $candidates.Count; $i++) { Write-Host ("[$i] " + $candidates[$i]) }
        $choice = Read-Host 'Choose installation number'
        return $candidates[[int]$choice]
    }
    $manual = Read-Host 'Enter the full path to the game retail folder'
    return $manual.Trim('"')
}

foreach ($name in $TargetNames) {
    if (-not (Test-Path -LiteralPath (Join-Path $PayloadRoot $name))) { throw "Package is incomplete. Missing payload: $name" }
}
if (-not $GameRetail) { $GameRetail = Find-GameRetail }
if (-not (Test-Path -LiteralPath (Join-Path $GameRetail 'DXMD.exe'))) { throw "DXMD.exe not found in: $GameRetail" }

$version = [Diagnostics.FileVersionInfo]::GetVersionInfo((Join-Path $GameRetail 'DXMD.exe')).FileVersion
if ($version -notmatch '1\.19') {
    Write-Warning "Detected DXMD.exe version '$version'. This package targets Steam v1.19."
    if ((Read-Host 'Continue anyway? (y/N)') -notmatch '^(y|yes)$') { exit 1 }
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup = Join-Path $GameRetail ("DXMD-Chinese-backup-$stamp")
New-Item -ItemType Directory -Path $backup -Force | Out-Null
$manifest = [ordered]@{ created = (Get-Date).ToString('o'); files = @() }
foreach ($name in $TargetNames) {
    $target = Join-Path $GameRetail $name
    $existed = Test-Path -LiteralPath $target
    $manifest.files += [ordered]@{ name = $name; existed = $existed }
    if ($existed) { Copy-Item -LiteralPath $target -Destination (Join-Path $backup $name) -Force }
}
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $backup 'backup-manifest.json') -Encoding UTF8

foreach ($name in $TargetNames) {
    Copy-Item -LiteralPath (Join-Path $PayloadRoot $name) -Destination (Join-Path $GameRetail $name) -Force
}

foreach ($name in $TargetNames) {
    $target = Join-Path $GameRetail $name
    if (-not (Test-Path -LiteralPath $target)) { throw "Install verification failed: $name" }
}

$runtimePaths = @(
    (Join-Path $env:WINDIR 'System32\vcruntime140_1.dll'),
    (Join-Path $env:WINDIR 'SysWOW64\vcruntime140_1.dll')
)
if (-not ($runtimePaths | Where-Object { Test-Path -LiteralPath $_ })) {
    Write-Warning 'MSVC runtime was not detected. If the game fails to start, install the latest x64 Microsoft Visual C++ Redistributable.'
}
Write-Host ''
Write-Host 'Chinese localization installed successfully.' -ForegroundColor Green
Write-Host ("Game:   " + $GameRetail)
Write-Host ("Backup: " + $backup)
Read-Host 'Press Enter to close'
