$ErrorActionPreference = "SilentlyContinue"
$logFile = "C:\Users\LocalServer\Documents\GitHub\9router\health-check.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

try {
    $response = Invoke-WebRequest -Uri "https://9router.shadowsplay.cloud" -TimeoutSec 10 -UseBasicParsing
    if ($response.StatusCode -ne 200) { throw "Status $($response.StatusCode)" }
} catch {
    "$timestamp - Tunnel DOWN ($_) - recuperando cloudflared..." | Add-Content $logFile
    & "C:\Users\LocalServer\Documents\GitHub\9router\recover-cloudflared.ps1"
    Start-Sleep -Seconds 10
}
