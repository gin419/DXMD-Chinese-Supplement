param(
    [Parameter(Mandatory = $true)] [string]$Archive,
    [string]$Index = (Join-Path (Split-Path -Parent $PSScriptRoot) 'archive-index.json'),
    [string]$Output = (Join-Path (Split-Path -Parent $PSScriptRoot) 'resource-samples.json'),
    [int64]$MaxBytes = 100KB
)

$ErrorActionPreference = 'Stop'
$catalog = Get-Content -LiteralPath $Index -Raw | ConvertFrom-Json
$stream = [IO.File]::OpenRead($Archive)
$results = [Collections.Generic.List[object]]::new()
try {
    foreach ($file in @($catalog.files | Where-Object { $_.name -like '*.pc_resourcelib' -and [int64]$_.totalLength -le $MaxBytes })) {
        if (@($file.chunks).Count -ne 1) { continue }
        $chunk = $file.chunks[0]
        if ([int64]$chunk.length -lt 28) { continue }
        $stream.Seek([int64]$chunk.offset, [IO.SeekOrigin]::Begin) | Out-Null
        $bytes = New-Object byte[] ([int64]$chunk.length)
        $read = $stream.Read($bytes, 0, $bytes.Length)
        if ($read -ne $bytes.Length) { continue }
        if ([Text.Encoding]::ASCII.GetString($bytes, 0, 4) -ne 'BILR') { continue }
        $mem = [IO.MemoryStream]::new($bytes)
        $br = [IO.BinaryReader]::new($mem)
        try {
            $br.ReadBytes(24) | Out-Null
            $count = $br.ReadUInt32()
            $samples = [Collections.Generic.List[string]]::new()
            $valid = $true
            for ($i = 0; $i -lt $count; $i++) {
                if ($mem.Position + 8 -gt $mem.Length) { $valid = $false; break }
                $br.ReadUInt32() | Out-Null
                $length = $br.ReadUInt32()
                if ($length -gt 1MB -or $mem.Position + $length + 1 -gt $mem.Length) { $valid = $false; break }
                $text = [Text.Encoding]::UTF8.GetString($br.ReadBytes($length))
                $br.ReadByte() | Out-Null
                if ($samples.Count -lt 5 -and $text.Length -gt 0) { $samples.Add($text) }
            }
            if ($valid) {
                $results.Add([ordered]@{ name = $file.name; size = [int64]$file.totalLength; entries = $count; samples = $samples })
            }
        } finally { $br.Dispose(); $mem.Dispose() }
    }
} finally { $stream.Dispose() }
$results | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $Output -Encoding UTF8
Write-Output "Wrote $($results.Count) resource samples to $Output"
