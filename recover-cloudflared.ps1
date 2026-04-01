$ErrorActionPreference = "Stop"

$serviceName = "cloudflared"
$service = Get-CimInstance Win32_Service -Filter "Name='cloudflared'"

if (-not $service) {
    throw "Service '$serviceName' not found."
}

if ($service.ProcessId -gt 0) {
    try {
        Stop-Process -Id $service.ProcessId -Force -ErrorAction Stop
        Start-Sleep -Seconds 3
    } catch {
        # Ignore if the process was already gone between queries.
    }
}

Start-Service $serviceName
Start-Sleep -Seconds 5

$status = (Get-Service $serviceName).Status
if ($status -ne "Running") {
    throw "Service '$serviceName' failed to start. Current status: $status"
}
