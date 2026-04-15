$ProjectDir = "C:\Users\LocalServer\Documents\GitHub\9router"
$NodeExe = "C:\Program Files\nodejs\node.exe"
$ServerJs = Join-Path $ProjectDir ".build\standalone\server.js"
$LogFile = Join-Path $ProjectDir "logs\9router-service.log"
$EnvFile = Join-Path $ProjectDir ".build\standalone\.env"

Set-Location $ProjectDir
New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null

$env:NODE_ENV = "production"
$env:PORT = "20128"
$env:HOSTNAME = "0.0.0.0"

if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith("#")) {
            $parts = $line -split "=", 2
            if ($parts.Length -eq 2) {
                $key = $parts[0].Trim()
                $val = $parts[1].Trim().Replace('\\', '\')
                [Environment]::SetEnvironmentVariable($key, $val, "Process")
            }
        }
    }
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"[$timestamp] Service wrapper starting: $NodeExe $ServerJs" | Add-Content $LogFile

$process = Start-Process -FilePath $NodeExe -ArgumentList $ServerJs -WorkingDirectory $ProjectDir -NoNewWindow -PassThru -RedirectStandardOutput (Join-Path $ProjectDir "logs\9router-stdout.log") -RedirectStandardError (Join-Path $ProjectDir "logs\9router-stderr.log")

"[$timestamp] Node PID: $($process.Id)" | Add-Content $LogFile

$process.WaitForExit()

$exitTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"[$exitTimestamp] Service exited with code: $($process.ExitCode)" | Add-Content $LogFile

exit $process.ExitCode
