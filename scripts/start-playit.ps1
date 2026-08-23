param(
    [Parameter(Mandatory = $true)][string]$Executable,
    [Parameter(Mandatory = $true)][string]$WorkingDirectory,
    [Parameter(Mandatory = $true)][string]$PidPath,
    [Parameter(Mandatory = $true)][string]$OwnershipPath
)

$resolvedExecutable = [System.IO.Path]::GetFullPath($Executable)
$existing = Get-CimInstance Win32_Process -Filter "Name = 'playit.exe'" |
    Where-Object { $_.ExecutablePath -and $_.ExecutablePath -ieq $resolvedExecutable } |
    Select-Object -First 1

if ($existing) {
    Set-Content -Path $OwnershipPath -Value "external" -Encoding ascii
    Write-Host "Using the existing playit agent (PID $($existing.ProcessId))."
    exit 0
}

if (-not (Test-Path -LiteralPath $resolvedExecutable)) {
    Write-Error "playit.exe was not found at $resolvedExecutable"
    exit 1
}

$process = Start-Process -FilePath $resolvedExecutable -WorkingDirectory $WorkingDirectory -PassThru
Set-Content -Path $PidPath -Value $process.Id -Encoding ascii
Set-Content -Path $OwnershipPath -Value "owned" -Encoding ascii
Write-Host "Started playit agent with PID $($process.Id)."
