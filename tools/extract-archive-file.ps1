param(
    [Parameter(Mandatory = $true)] [string]$Archive,
    [Parameter(Mandatory = $true)] [string]$Entry,
    [Parameter(Mandatory = $true)] [string]$Output
)

$ErrorActionPreference = 'Stop'
$indexPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'archive-index.json'
if (-not (Test-Path -LiteralPath $indexPath)) {
    throw "Run archive-index.ps1 first to generate $indexPath"
}
$index = Get-Content -LiteralPath $indexPath -Raw | ConvertFrom-Json
$file = @($index.files | Where-Object { $_.name -eq $Entry }) | Select-Object -First 1
if ($null -eq $file) { throw "Entry not found in index: $Entry" }

$parent = Split-Path -Parent $Output
if ($parent -and -not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent | Out-Null }
$input = [IO.File]::OpenRead($Archive)
$writer = [IO.File]::Create($Output)
try {
    foreach ($chunk in $file.chunks) {
        if ($chunk.archive -ne 0) { throw "This tool only supports single-archive chunks; got archive=$($chunk.archive)" }
        $input.Seek([Int64]$chunk.offset, [IO.SeekOrigin]::Begin) | Out-Null
        $remaining = [Int64]$chunk.length
        $buffer = New-Object byte[] (4MB)
        while ($remaining -gt 0) {
            $wanted = [Math]::Min($remaining, $buffer.Length)
            $read = $input.Read($buffer, 0, [int]$wanted)
            if ($read -le 0) { throw 'Unexpected end of archive data' }
            $writer.Write($buffer, 0, $read)
            $remaining -= $read
        }
    }
} finally {
    $writer.Dispose()
    $input.Dispose()
}
Write-Output "Extracted: $Output"
