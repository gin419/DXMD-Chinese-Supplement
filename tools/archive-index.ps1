param(
    [Parameter(Mandatory = $true)]
    [string]$Archive,
    [string]$Output = (Join-Path (Split-Path -Parent $PSScriptRoot) 'archive-index.json')
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $Archive)) { throw "Archive not found: $Archive" }

function Read-ArchiveString([System.IO.BinaryReader]$Reader) {
    $length = $Reader.ReadUInt32()
    if ($length -gt 16MB) { throw "Invalid string length: $length" }
    $bytes = $Reader.ReadBytes($length)
    if ($bytes.Length -ne $length) { throw 'Unexpected end of archive' }
    $terminator = $Reader.ReadByte()
    if ($terminator -ne 0) { throw 'Missing null terminator' }
    return [Text.Encoding]::UTF8.GetString($bytes)
}

$stream = [IO.File]::OpenRead($Archive)
$reader = [IO.BinaryReader]::new($stream)
try {
    $magic = [Text.Encoding]::ASCII.GetString($reader.ReadBytes(4))
    if ($magic -ne 'ARCH') { throw "Not a DXMD ARCH archive: $magic" }
    $version = $reader.ReadUInt32()
    $fileCount = $reader.ReadUInt32()
    $linkCount = $reader.ReadUInt32()
    $directoryOffset = $reader.ReadUInt64()
    $stream.Seek([Int64]$directoryOffset, [IO.SeekOrigin]::Begin) | Out-Null

    $links = @()
    for ($i = 0; $i -lt $linkCount; $i++) { $links += Read-ArchiveString $reader }

    $files = [Collections.Generic.List[object]]::new()
    for ($i = 0; $i -lt $fileCount; $i++) {
        $reader.ReadBytes(24) | Out-Null # timestamp + opaque hash
        $name = Read-ArchiveString $reader
        $chunkCount = $reader.ReadUInt32()
        $chunks = [Collections.Generic.List[object]]::new()
        $totalLength = [UInt64]0
        for ($j = 0; $j -lt $chunkCount; $j++) {
            $chunk = [ordered]@{
                archive = $reader.ReadUInt32()
                begin = $reader.ReadUInt64()
                offset = $reader.ReadUInt64()
                length = $reader.ReadUInt64()
            }
            $chunks.Add($chunk)
            $totalLength += $chunk.length
        }
        $files.Add([ordered]@{
            name = $name
            chunks = $chunks
            totalLength = $totalLength
        })
    }
} finally {
    $reader.Dispose()
    $stream.Dispose()
}

[ordered]@{
    archive = (Resolve-Path -LiteralPath $Archive).Path
    version = $version
    fileCount = $fileCount
    linkCount = $linkCount
    directoryOffset = $directoryOffset
    links = $links
    files = $files
} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Output -Encoding UTF8
Write-Output "Wrote: $Output"
