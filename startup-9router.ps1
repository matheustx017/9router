$ErrorActionPreference = "Stop"

$projectDir = "C:\Users\LocalServer\Documents\GitHub\9router"
$logFile = Join-Path $projectDir "startup-9router.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$runtimeScript = Join-Path $projectDir "scripts\9router-runtime.ps1"

try {
    if (-not (Test-Path $runtimeScript)) { throw "runtime helpers not found at $runtimeScript" }

    Set-Location $projectDir
    . $runtimeScript

    Write-9RouterLog -LogFile $logFile -Message "Startup task running in global CLI mode."

    $cliPath = Get-9RouterCliPath
    Stop-9RouterListeners -Port 20128 -LogFile $logFile
    Start-9RouterCli -CliPath $cliPath -LogFile $logFile -Port 20128 | Out-Null

    $validated = $false
    for ($attempt = 1; $attempt -le 6; $attempt++) {
        Start-Sleep -Seconds 5
        try {
            Test-9RouterServedAssets -Port 20128 | Out-Null
            $validated = $true
            break
        } catch {
            Write-9RouterLog -LogFile $logFile -Message "Startup validation attempt $attempt failed: $_"
        }
    }

    if (-not $validated) {
        throw "Global CLI validation failed after startup."
    }

    Write-9RouterLog -LogFile $logFile -Message "Startup validation passed."
    Write-9RouterLog -LogFile $logFile -Message "Startup task completed."
} catch {
    Write-9RouterLog -LogFile $logFile -Message "Startup task failed: $_"
    exit 1
}
