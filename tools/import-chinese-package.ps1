param(
    [Parameter(Mandatory = $true)] [string]$Zip,
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $Zip)) { throw "Package not found: $Zip" }
$stage = Join-Path $ProjectRoot 'work\chinese-package'
if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
New-Item -ItemType Directory -Path $stage | Out-Null
Expand-Archive -LiteralPath $Zip -DestinationPath $stage -Force
$files = Get-ChildItem -LiteralPath $stage -Recurse -File
if ($files.Count -eq 0) { throw 'Package contains no files' }
$files | Select-Object FullName,Length | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $ProjectRoot 'work\chinese-package-manifest.json') -Encoding UTF8
Write-Output "Imported $($files.Count) files into $stage"
