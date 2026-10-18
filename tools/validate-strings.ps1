param(
    [Parameter(Mandatory = $true)] [string]$Strings,
    [string]$Reference
)

$ErrorActionPreference = 'Stop'
$json = Get-Content -LiteralPath $Strings -Raw | ConvertFrom-Json
if ($null -eq $json) { throw 'Invalid or empty JSON' }
$raw = Get-Content -LiteralPath $Strings -Raw
$cjk = ([regex]::Matches($raw, '[\u3400-\u9FFF]')).Count
$result = [ordered]@{
    file = (Resolve-Path -LiteralPath $Strings).Path
    bytes = (Get-Item -LiteralPath $Strings).Length
    top_level_type = $json.GetType().FullName
    chinese_codepoints = $cjk
    valid_json = $true
}
if ($Reference) {
    $ref = Get-Content -LiteralPath $Reference -Raw | ConvertFrom-Json
    $result.reference_bytes = (Get-Item -LiteralPath $Reference).Length
    $result.reference_top_level_type = $ref.GetType().FullName
}
$result | ConvertTo-Json
