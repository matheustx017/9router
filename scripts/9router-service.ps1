param(
    [Parameter(Position=0)]
    [ValidateSet("install","uninstall","start","stop","status")]
    [string]$Action = "status"
)

$ServiceName = "9Router"
$ServiceDisplay = "9Router App Server"
$ProjectDir = "C:\Users\LocalServer\Documents\GitHub\9router"
$NodeExe = "C:\Program Files\nodejs\node.exe"
$ServerJs = Join-Path $ProjectDir ".build\standalone\server.js"
$LogDir = Join-Path $ProjectDir "logs"
$WrapperScript = Join-Path $ProjectDir "scripts\9router-service-wrapper.ps1"

switch ($Action) {
    "install" {
        if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
            Write-Host "Service '$ServiceName' already exists. Use 'uninstall' first."
            return
        }

        if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

        $binPath = "powershell.exe -ExecutionPolicy Bypass -NonInteractive -File `"$WrapperScript`""

        sc.exe create $ServiceName binPath= $binPath start= delayed-auto DisplayName= $ServiceDisplay
        sc.exe description $ServiceName "9Router Next.js standalone server"
        sc.exe failure $ServiceName reset= 60 actions= restart/5000/restart/10000/restart/30000

        Write-Host "Service '$ServiceName' installed successfully."
        Write-Host "Start with: .\scripts\9router-service.ps1 start"
    }

    "uninstall" {
        $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if (-not $svc) {
            Write-Host "Service '$ServiceName' not found."
            return
        }
        if ($svc.Status -eq "Running") { sc.exe stop $ServiceName; Start-Sleep -Seconds 5 }
        sc.exe delete $ServiceName
        Write-Host "Service '$ServiceName' uninstalled."
    }

    "start" {
        sc.exe start $ServiceName
    }

    "stop" {
        sc.exe stop $ServiceName
    }

    "status" {
        $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($svc) {
            Write-Host "Service: $ServiceName | Status: $($svc.Status) | StartType: $($svc.StartType)"
        } else {
            Write-Host "Service '$ServiceName' not found."
        }
    }
}
