param(
    [Parameter(Mandatory = $true)][string]$ConfigPath,
    [Parameter(Mandatory = $true)][int]$BedrockPort,
    [int]$BroadcastPort = 0,
    [bool]$UseHaproxyProtocol = $false
)

if (-not (Test-Path -LiteralPath $ConfigPath)) {
    Write-Host "Geyser config is not generated yet: $ConfigPath"
    exit 0
}

# Safe line-based editor. Tracks the YAML section path (e.g. "advanced.bedrock")
# from indentation so edits target exactly the right keys, unlike the previous
# file-spanning regexes which corrupted the config.
$lines = Get-Content -LiteralPath $ConfigPath
$out = [System.Collections.Generic.List[string]]::new()
$stack = New-Object 'System.Collections.Generic.Stack[object]'

function Get-KeyPath {
    $names = @($stack | ForEach-Object { $_.name })
    [array]::Reverse($names)
    return ($names -join '.')
}

foreach ($line in $lines) {
    $trimmed = $line.Trim()

    if ($trimmed -eq '' -or $trimmed.StartsWith('#')) {
        $out.Add($line)
        continue
    }

    $indent = 0
    foreach ($ch in $line.ToCharArray()) {
        if ($ch -eq ' ') { $indent++ } else { break }
    }

    # Section header (a bare "key:" line)
    if ($trimmed -match '^([A-Za-z0-9_-]+):\s*$') {
        $key = $Matches[1].ToLowerInvariant()
        while ($stack.Count -gt 0 -and $indent -le $stack.Peek().indent) { [void]$stack.Pop() }
        $stack.Push([pscustomobject]@{ name = $key; indent = $indent })
        $out.Add($line)
        continue
    }

    # key: value line
    if ($trimmed -match '^([A-Za-z0-9_-]+):\s*(.*)$') {
        $key = $Matches[1].ToLowerInvariant()
        $path = Get-KeyPath
        $newLine = $line

        if ($path -eq 'bedrock' -and $key -eq 'port') {
            $newLine = $line -replace ':\s*\d+\s*$', ": $BedrockPort"
        }
        elseif ($key -eq 'auth-type') {
            $newLine = $line -replace ':\s*\S+\s*$', ': floodgate'
        }
        elseif ($BroadcastPort -gt 0 -and $path -eq 'advanced.bedrock') {
            if ($key -eq 'broadcast-port') {
                $newLine = $line -replace ':\s*\d+\s*$', ": $BroadcastPort"
            }
            elseif ($key -eq 'use-haproxy-protocol') {
                $haproxyValue = if ($UseHaproxyProtocol) { 'true' } else { 'false' }
                $newLine = $line -replace ':\s*(true|false)\s*$', ": $haproxyValue"
            }
        }

        $out.Add($newLine)
        continue
    }

    $out.Add($line)
}

[IO.File]::WriteAllLines($ConfigPath, $out, (New-Object Text.UTF8Encoding($false)))
$haproxy = if ($UseHaproxyProtocol) { 'true' } else { 'false' }
Write-Host "Configured Geyser: auth-type=floodgate, Bedrock UDP port=$BedrockPort, broadcast-port=$BroadcastPort, use-haproxy-protocol=$haproxy."
