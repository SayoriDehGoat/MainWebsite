param(
    [Parameter(Mandatory = $true)][string]$ConfigPath,
    [Parameter(Mandatory = $true)][int]$BedrockPort,
    [int]$BroadcastPort = 0
)

if (-not (Test-Path -LiteralPath $ConfigPath)) {
    Write-Host "Geyser config is not generated yet: $ConfigPath"
    exit 0
}

$content = Get-Content -Raw -LiteralPath $ConfigPath
$content = [regex]::Replace($content, '(?m)^(\s*auth-type:\s*).*$','$1floodgate')
$content = [regex]::Replace($content, '(?ms)(bedrock:\s*.*?^\s*port:\s*)\d+', "`$1$BedrockPort")

if ($BroadcastPort -gt 0) {
    $content = [regex]::Replace($content, '(?ms)(advanced:\s*.*?bedrock:\s*.*?^\s*broadcast-port:\s*)\d+', "`$1$BroadcastPort")
    $content = [regex]::Replace($content, '(?ms)(advanced:\s*.*?bedrock:\s*.*?^\s*use-haproxy-protocol:\s*).*$','${1}true')
    Write-Host "Configured Playit Bedrock public port $BroadcastPort and HAProxy protocol."
}

[IO.File]::WriteAllText($ConfigPath, $content, (New-Object Text.UTF8Encoding($false)))
Write-Host "Configured Geyser auth-type=floodgate and local Bedrock UDP port $BedrockPort."
