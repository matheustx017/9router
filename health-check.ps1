$ErrorActionPreference = "SilentlyContinue"
$logFile = "C:\Users\LocalServer\Documents\GitHub\9router\health-check.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$nodeExe = "C:\Program Files\nodejs\node.exe"
$pm2Bin = "C:\Users\LocalServer\AppData\Roaming\npm\node_modules\pm2\bin\pm2"
$env:PM2_HOME = "C:\Users\LocalServer\.pm2"

function Invoke-Pm2 {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    & $nodeExe $pm2Bin @Arguments
}

try {
    $response = Invoke-WebRequest -Uri "http://localhost:20128" -TimeoutSec 5 -UseBasicParsing
    if ($response.StatusCode -ne 200) { throw "Status $($response.StatusCode)" }
} catch {
    "$timestamp - 9Router DOWN ($_) - reiniciando..." | Add-Content $logFile
    Invoke-Pm2 restart 9router
    Start-Sleep -Seconds 15

    try {
        $retry = Invoke-WebRequest -Uri "http://localhost:20128" -TimeoutSec 5 -UseBasicParsing
        if ($retry.StatusCode -ne 200) { throw "Status $($retry.StatusCode)" }
    } catch {
        "$timestamp - 9Router ainda indisponivel, executando task de boot..." | Add-Content $logFile
        Start-ScheduledTask -TaskName "9Router-BootStart"
        Start-Sleep -Seconds 20
    }
}
