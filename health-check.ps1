$ErrorActionPreference = "SilentlyContinue"
$logFile = "C:\Users\LocalServer\Documents\GitHub\9router\health-check.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$projectDir = "C:\Users\LocalServer\Documents\GitHub\9router"
$runtimeScript = Join-Path $projectDir "scripts\9router-runtime.ps1"

if (Test-Path $runtimeScript) {
    . $runtimeScript
}

try {
    Test-9RouterServedAssets -Port 20128 | Out-Null
} catch {
    "$timestamp - 9Router DOWN ($_) - reiniciando..." | Add-Content $logFile

    $cliPath = Get-9RouterCliPath
    Stop-9RouterListeners -Port 20128 -LogFile $logFile
    Start-9RouterCli -CliPath $cliPath -LogFile $logFile -Port 20128 | Out-Null
    "$timestamp - Started global CLI as fallback." | Add-Content $logFile

    Start-Sleep -Seconds 10

    try {
        Test-9RouterServedAssets -Port 20128 | Out-Null
    } catch {
        "$timestamp - 9Router still down after restart, running boot task..." | Add-Content $logFile
        Start-ScheduledTask -TaskName "9Router-BootStart"
        Start-Sleep -Seconds 20
    }
}
