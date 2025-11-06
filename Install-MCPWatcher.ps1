#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Installs the MCP configuration watcher as a Windows Scheduled Task.

.DESCRIPTION
    Creates a scheduled task that runs the Watch-MCPServers.ps1 script in the background.
    The task starts at logon and runs hidden without a visible window.

.PARAMETER Uninstall
    Removes the scheduled task instead of installing it.

.EXAMPLE
    .\Install-MCPWatcher.ps1
    Installs the watcher as a scheduled task

.EXAMPLE
    .\Install-MCPWatcher.ps1 -Uninstall
    Removes the scheduled task
#>

[CmdletBinding()]
param(
    [Parameter()]
    [switch]$Uninstall
)

$TaskName = "MCP-ConfigWatcher"
$WatcherScript = Join-Path $PSScriptRoot "Watch-MCPServers.ps1"

if ($Uninstall) {
    Write-Host "Uninstalling MCP Configuration Watcher..." -ForegroundColor Yellow

    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

    if ($task) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "Successfully removed scheduled task: $TaskName" -ForegroundColor Green
    }
    else {
        Write-Host "Scheduled task not found: $TaskName" -ForegroundColor Yellow
    }

    exit 0
}

# Install
Write-Host "Installing MCP Configuration Watcher..." -ForegroundColor Yellow

if (-not (Test-Path $WatcherScript)) {
    Write-Host "ERROR: Watcher script not found: $WatcherScript" -ForegroundColor Red
    exit 1
}

# Remove existing task if it exists
$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Host "Removing existing task..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# Create the scheduled task action
$action = New-ScheduledTaskAction `
    -Execute "pwsh.exe" `
    -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$WatcherScript`""

# Create the trigger (at logon)
$trigger = New-ScheduledTaskTrigger -AtLogOn

# Create the principal (run as current user)
$principal = New-ScheduledTaskPrincipal `
    -UserId $env:USERNAME `
    -LogonType Interactive `
    -RunLevel Limited

# Create the settings
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -ExecutionTimeLimit (New-TimeSpan -Days 0)

# Register the task
Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Settings $settings `
    -Description "Monitors MCP server configuration files and triggers synchronization on changes" | Out-Null

Write-Host "`nScheduled task created successfully!" -ForegroundColor Green
Write-Host "`nTask Name: $TaskName" -ForegroundColor Cyan
Write-Host "Script: $WatcherScript" -ForegroundColor Cyan
Write-Host "`nThe watcher will start automatically at logon." -ForegroundColor Yellow
Write-Host "`nTo start it now, run:" -ForegroundColor Yellow
Write-Host "  Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
Write-Host "`nTo stop it, run:" -ForegroundColor Yellow
Write-Host "  Stop-ScheduledTask -TaskName '$TaskName'" -ForegroundColor White
Write-Host "`nTo check status, run:" -ForegroundColor Yellow
Write-Host "  Get-ScheduledTask -TaskName '$TaskName' | Select-Object State,LastRunTime,LastTaskResult" -ForegroundColor White
Write-Host "`nTo view logs, check:" -ForegroundColor Yellow
Write-Host "  `$env:TEMP\watch-mcp-debug.log" -ForegroundColor White

exit 0
