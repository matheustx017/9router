$ErrorActionPreference = "Stop"

$projectDir = "C:\Users\LocalServer\Documents\GitHub\9router"
$logFile = Join-Path $projectDir "startup-9router.log"
$nodeExe = "C:\Program Files\nodejs\node.exe"
$pm2Bin = "C:\Users\LocalServer\AppData\Roaming\npm\node_modules\pm2\bin\pm2"
$pm2Home = "C:\Users\LocalServer\.pm2"
$assetScript = Join-Path $projectDir "scripts\prepare-standalone-assets.mjs"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

function Invoke-Pm2 {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    & $nodeExe $pm2Bin @Arguments
}

try {
    if (-not (Test-Path $nodeExe)) { throw "node.exe not found at $nodeExe" }
    if (-not (Test-Path $pm2Bin)) { throw "PM2 binary not found at $pm2Bin" }
    if (-not (Test-Path $assetScript)) { throw "Asset sync script not found at $assetScript" }

    $env:PM2_HOME = $pm2Home
    Set-Location $projectDir

    "[$timestamp] Startup task running." | Add-Content $logFile
    (& $nodeExe $assetScript 2>&1 | Out-String) | Add-Content $logFile
    (Invoke-Pm2 resurrect 2>&1 | Out-String) | Add-Content $logFile

    Start-Sleep -Seconds 10

    $pidOutput = (Invoke-Pm2 pid 9router 2>$null | Out-String).Trim()
    if (-not $pidOutput -or $pidOutput -eq "0") {
        "[$timestamp] 9router not online after resurrect, starting ecosystem config." | Add-Content $logFile
        (Invoke-Pm2 start ".\ecosystem.config.cjs" 2>&1 | Out-String) | Add-Content $logFile
        (Invoke-Pm2 save 2>&1 | Out-String) | Add-Content $logFile
    }

    "[$timestamp] Startup task completed." | Add-Content $logFile
} catch {
    "[$timestamp] Startup task failed: $_" | Add-Content $logFile
    exit 1
}
