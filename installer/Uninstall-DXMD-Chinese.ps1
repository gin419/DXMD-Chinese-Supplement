param(
    [string]$GameRetail = ''
)

$ErrorActionPreference = 'Stop'
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
if (-not $GameRetail) { $GameRetail = Read-Host 'Enter the full path to the game retail folder' }
if (-not (Test-Path -LiteralPath $GameRetail)) { throw "Game directory not found: $GameRetail" }
$backup = Get-ChildItem -LiteralPath $GameRetail -Directory -Filter 'DXMD-Chinese-backup-*' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $backup) { throw 'No DXMD-Chinese backup was found.' }
$manifestPath = Join-Path $backup.FullName 'backup-manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath)) { throw "Backup manifest missing: $manifestPath" }
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
foreach ($item in $manifest.files) {
    $target = Join-Path $GameRetail $item.name
    $saved = Join-Path $backup.FullName $item.name
    if ($item.existed) {
        Copy-Item -LiteralPath $saved -Destination $target -Force
    } elseif (Test-Path -LiteralPath $target) {
        Remove-Item -LiteralPath $target -Force
    }
}
Write-Host 'Original files restored.' -ForegroundColor Green
Write-Host ("Backup retained at: " + $backup.FullName)
Read-Host 'Press Enter to close'
