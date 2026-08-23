param(
    [Parameter(Mandatory = $true)][string]$Executable,
    [Parameter(Mandatory = $true)][string]$PidPath,
    [Parameter(Mandatory = $true)][string]$OwnershipPath
)

if (-not (Test-Path -LiteralPath $OwnershipPath) -or (Get-Content -Raw -LiteralPath $OwnershipPath).Trim() -ne "owned") {
    exit 0
}
if (-not (Test-Path -LiteralPath $PidPath)) {
    exit 0
}

$agentPid = [int](Get-Content -Raw -LiteralPath $PidPath).Trim()
$resolvedExecutable = [System.IO.Path]::GetFullPath($Executable)
$process = Get-CimInstance Win32_Process -Filter "ProcessId = $agentPid" -ErrorAction SilentlyContinue
if ($process -and $process.Name -ieq "playit.exe" -and $process.ExecutablePath -ieq $resolvedExecutable) {
    Stop-Process -Id $agentPid -Force -ErrorAction SilentlyContinue
    Write-Host "Stopped the playit agent started by this launcher (PID $agentPid)."
}

Remove-Item -Force -ErrorAction SilentlyContinue $PidPath, $OwnershipPath
