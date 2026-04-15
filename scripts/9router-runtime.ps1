function Write-9RouterLog {
    param(
        [string]$LogFile,
        [string]$Message
    )

    if (-not $LogFile) {
        return
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] $Message" | Add-Content $LogFile
}

function Get-9RouterListeningPids {
    param(
        [int]$Port = 20128
    )

    try {
        @(Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction Stop |
            Select-Object -ExpandProperty OwningProcess -Unique)
    } catch {
        @()
    }
}

function Stop-9RouterListeners {
    param(
        [int]$Port = 20128,
        [string]$LogFile
    )

    foreach ($listenerPid in (Get-9RouterListeningPids -Port $Port)) {
        if (-not $listenerPid -or $listenerPid -eq $PID) {
            continue
        }

        try {
            Stop-Process -Id $listenerPid -Force -ErrorAction Stop
            Write-9RouterLog -LogFile $LogFile -Message "Stopped existing listener PID $listenerPid on port $Port."
            Start-Sleep -Seconds 2
        } catch {
            Write-9RouterLog -LogFile $LogFile -Message "Failed to stop listener PID $listenerPid on port ${Port}: $_"
        }
    }
}

function Start-9RouterStandalone {
    param(
        [string]$NodeExe,
        [string]$StandaloneServer,
        [string]$ProjectDir,
        [string]$LogFile,
        [int]$Port = 20128
    )

    if (-not (Test-Path $StandaloneServer)) {
        throw "Standalone server not found at $StandaloneServer"
    }

    $env:NODE_ENV = "production"
    $env:PORT = "$Port"
    $env:HOSTNAME = "0.0.0.0"

    $process = Start-Process -FilePath $NodeExe -ArgumentList $StandaloneServer -WorkingDirectory $ProjectDir -WindowStyle Hidden -PassThru
    Write-9RouterLog -LogFile $LogFile -Message "Started standalone server PID $($process.Id) on port $Port."
    return $process
}

function Get-9RouterCliPath {
    $candidatePaths = @(
        (Join-Path $env:APPDATA "npm\9router.cmd"),
        (Join-Path $env:APPDATA "npm\9router")
    )

    $cliPath = $candidatePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $cliPath) {
        throw "Global 9router CLI not found. Expected one of: $($candidatePaths -join ', ')"
    }

    return $cliPath
}

function Start-9RouterCli {
    param(
        [string]$CliPath,
        [string]$LogFile,
        [int]$Port = 20128
    )

    if (-not (Test-Path $CliPath)) {
        throw "Global 9router CLI not found at $CliPath"
    }

    $arguments = @("--no-browser", "--skip-update", "--port", "$Port")
    $process = Start-Process -FilePath $CliPath -ArgumentList $arguments -WindowStyle Hidden -PassThru
    Write-9RouterLog -LogFile $LogFile -Message "Started global 9router CLI PID $($process.Id) on port $Port."
    return $process
}

function Get-9RouterServedAssets {
    param(
        [string]$Html
    )

    $allAssets = [regex]::Matches($Html, '/_next/static/[^"''<]+') |
        ForEach-Object { $_.Value.TrimEnd('\') } |
        Sort-Object -Unique

    $priorityAssets = @(
        $allAssets | Where-Object { $_ -match '/chunks/app/login/' } | Select-Object -First 1
        $allAssets | Where-Object { $_ -match '/static/css/' } | Select-Object -First 2
        $allAssets | Where-Object { $_ -match '/chunks/webpack-' } | Select-Object -First 1
    ) | Where-Object { $_ }

    if (-not $priorityAssets) {
        $priorityAssets = $allAssets | Select-Object -First 4
    }

    if (-not $priorityAssets) {
        throw "Could not determine served assets from login HTML"
    }

    $priorityAssets | Select-Object -Unique
}

function Test-9RouterServedAssets {
    param(
        [int]$Port = 20128
    )

    $response = Invoke-WebRequest -Uri "http://localhost:$Port/login" -TimeoutSec 5 -UseBasicParsing
    if ($response.StatusCode -ne 200) {
        throw "Login returned status $($response.StatusCode)"
    }

    $servedAssets = Get-9RouterServedAssets -Html $response.Content

    foreach ($assetPath in $servedAssets) {
        if ($response.Content -notmatch [regex]::Escape($assetPath)) {
            throw "Served HTML is stale; missing asset $assetPath"
        }

        $assetResponse = Invoke-WebRequest -Uri "http://localhost:$Port$assetPath" -TimeoutSec 5 -UseBasicParsing
        if ($assetResponse.StatusCode -ne 200) {
            throw "Asset $assetPath returned status $($assetResponse.StatusCode)"
        }
    }

    return $true
}

function Get-9RouterExpectedAssets {
    param(
        [string]$ProjectDir
    )

    $candidatePaths = @(
        (Join-Path $ProjectDir ".build\server\app\login.html"),
        (Join-Path $ProjectDir ".build\standalone\.build\server\app\login.html")
    )

    $expectedHtmlPath = $candidatePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $expectedHtmlPath) {
        throw "Current build login HTML not found."
    }

    $expectedHtml = Get-Content $expectedHtmlPath -Raw
    $allAssets = [regex]::Matches($expectedHtml, '/_next/static/[^"''<]+') |
        ForEach-Object { $_.Value.TrimEnd('\') } |
        Sort-Object -Unique

    $priorityAssets = @(
        $allAssets | Where-Object { $_ -match '/chunks/app/login/' } | Select-Object -First 1
        $allAssets | Where-Object { $_ -match '/static/css/' } | Select-Object -First 2
        $allAssets | Where-Object { $_ -match '/chunks/webpack-' } | Select-Object -First 1
    ) | Where-Object { $_ }

    if (-not $priorityAssets) {
        throw "Could not determine expected login assets from $expectedHtmlPath"
    }

    $priorityAssets | Select-Object -Unique
}

function Test-9RouterCurrentBuild {
    param(
        [string]$ProjectDir,
        [int]$Port = 20128
    )

    $response = Invoke-WebRequest -Uri "http://localhost:$Port/login" -TimeoutSec 5 -UseBasicParsing
    if ($response.StatusCode -ne 200) {
        throw "Login returned status $($response.StatusCode)"
    }

    $expectedAssets = Get-9RouterExpectedAssets -ProjectDir $ProjectDir

    foreach ($assetPath in $expectedAssets) {
        if ($response.Content -notmatch [regex]::Escape($assetPath)) {
            throw "Served HTML is stale; missing expected asset $assetPath"
        }

        $assetResponse = Invoke-WebRequest -Uri "http://localhost:$Port$assetPath" -TimeoutSec 5 -UseBasicParsing
        if ($assetResponse.StatusCode -ne 200) {
            throw "Asset $assetPath returned status $($assetResponse.StatusCode)"
        }
    }

    return $true
}
