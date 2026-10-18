param(
    [Parameter(Mandatory = $true)] [string]$Archive,
    [string]$Index = (Join-Path (Split-Path -Parent $PSScriptRoot) 'archive-index.json'),
    [string]$Output = (Join-Path (Split-Path -Parent $PSScriptRoot) 'work\bilr-corpus.jsonl'),
    [int64]$MaxBytes = 100KB
)

$ErrorActionPreference = 'Stop'
$catalog = Get-Content -LiteralPath $Index -Raw | ConvertFrom-Json
$parent = Split-Path -Parent $Output
if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent | Out-Null }
$stream = [IO.File]::OpenRead($Archive)
$writer = [IO.StreamWriter]::new($Output, $false, [Text.UTF8Encoding]::new($false))
$resourceCount = 0
$entryCount = 0
try {
    foreach ($file in @($catalog.files | Where-Object { $_.name -like '*.pc_resourcelib' -and [int64]$_.totalLength -le $MaxBytes })) {
        if (@($file.chunks).Count -ne 1) { continue }
        $chunk = $file.chunks[0]
        if ([int64]$chunk.length -lt 28) { continue }
        $stream.Seek([int64]$chunk.offset, [IO.SeekOrigin]::Begin) | Out-Null
        $bytes = New-Object byte[] ([int64]$chunk.length)
        if ($stream.Read($bytes, 0, $bytes.Length) -ne $bytes.Length) { continue }
        if ([Text.Encoding]::ASCII.GetString($bytes, 0, 4) -ne 'BILR') { continue }
        $mem = [IO.MemoryStream]::new($bytes)
        $br = [IO.BinaryReader]::new($mem)
        try {
            $br.ReadBytes(24) | Out-Null
            $count = $br.ReadUInt32()
            $entries = [Collections.Generic.List[object]]::new()
            $valid = $true
            for ($i = 0; $i -lt $count; $i++) {
                if ($mem.Position + 8 -gt $mem.Length) { $valid = $false; break }
                $id = $br.ReadUInt32()
                $length = $br.ReadUInt32()
                if ($length -gt 1MB -or $mem.Position + $length + 1 -gt $mem.Length) { $valid = $false; break }
                $text = [Text.Encoding]::UTF8.GetString($br.ReadBytes($length))
                $br.ReadByte() | Out-Null
                # Base64 keeps JSONL valid even when a game string contains CR/LF.
                $textB64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($text))
                $entries.Add([ordered]@{ id = [uint32]$id; text_b64 = $textB64 })
            }
            if ($valid) {
                $obj = [ordered]@{ resource_file = $file.name; entries = $entries }
                $writer.WriteLine(($obj | ConvertTo-Json -Depth 6 -Compress))
                $resourceCount++
                $entryCount += $entries.Count
            }
        } finally { $br.Dispose(); $mem.Dispose() }
    }
} finally {
    $writer.Dispose()
    $stream.Dispose()
}
Write-Output "Wrote $resourceCount resources / $entryCount entries to $Output"
