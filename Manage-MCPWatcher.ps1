#Requires -Version 5.1

<#
.SYNOPSIS
    Manages the MCP Configuration Watcher scheduled task.

.DESCRIPTION
    Provides commands to start, stop, restart, check status, and view logs for the MCP watcher.

.PARAMETER Action
    The action to perform: Start, Stop, Restart, Status, Logs, or Install

.EXAMPLE
    .\Manage-MCPWatcher.ps1 -Action Start
    Starts the watcher

.EXAMPLE
    .\Manage-MCPWatcher.ps1 -Action Status
    Shows the current status

.EXAMPLE
    .\Manage-MCPWatcher.ps1 -Action Logs
    Displays the last 50 lines of the log file
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Start", "Stop", "Restart", "Status", "Logs", "Install", "Uninstall")]
    [string]$Action
)

$TaskName = "MCP-ConfigWatcher"
$LogFile = "$env:TEMP\watch-mcp-debug.log"
$InstallScript = Join-Path $PSScriptRoot "Install-MCPWatcher.ps1"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Get-WatcherStatus {
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

    if (-not $task) {
        Write-ColorOutput "Watcher is NOT installed" "Red"
        Write-ColorOutput "Run: .\Manage-MCPWatcher.ps1 -Action Install" "Yellow"
        return $null
    }

    $info = Get-ScheduledTaskInfo -TaskName $TaskName -ErrorAction SilentlyContinue

    Write-ColorOutput "`nMCP Configuration Watcher Status:" "Cyan"
    Write-ColorOutput "  State: $($task.State)" $(if ($task.State -eq "Running") { "Green" } else { "Yellow" })
    Write-ColorOutput "  Last Run: $($info.LastRunTime)" "Gray"
    Write-ColorOutput "  Last Result: $($info.LastTaskResult)" $(if ($info.LastTaskResult -eq 0) { "Green" } else { "Red" })
    Write-ColorOutput "  Next Run: $($info.NextRunTime)" "Gray"

    return $task
}

switch ($Action) {
    "Start" {
        $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if (-not $task) {
            Write-ColorOutput "ERROR: Watcher is not installed. Run with -Action Install first." "Red"
            exit 1
        }

        Write-ColorOutput "Starting MCP watcher..." "Yellow"
        Start-ScheduledTask -TaskName $TaskName
        Start-Sleep -Seconds 2
        Get-WatcherStatus
    }

    "Stop" {
        $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if (-not $task) {
            Write-ColorOutput "ERROR: Watcher is not installed." "Red"
            exit 1
        }

        Write-ColorOutput "Stopping MCP watcher..." "Yellow"
        Stop-ScheduledTask -TaskName $TaskName
        Start-Sleep -Seconds 2
        Get-WatcherStatus
    }

    "Restart" {
        $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if (-not $task) {
            Write-ColorOutput "ERROR: Watcher is not installed." "Red"
            exit 1
        }

        Write-ColorOutput "Restarting MCP watcher..." "Yellow"
        Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Start-ScheduledTask -TaskName $TaskName
        Start-Sleep -Seconds 2
        Get-WatcherStatus
    }

    "Status" {
        Get-WatcherStatus
    }

    "Logs" {
        if (Test-Path $LogFile) {
            Write-ColorOutput "`nLast 50 log entries:" "Cyan"
            Write-ColorOutput "Location: $LogFile`n" "Gray"
            Get-Content $LogFile -Tail 50
        }
        else {
            Write-ColorOutput "Log file not found: $LogFile" "Yellow"
            Write-ColorOutput "The watcher may not have started yet." "Yellow"
        }
    }

    "Install" {
        if (-not (Test-Path $InstallScript)) {
            Write-ColorOutput "ERROR: Install script not found: $InstallScript" "Red"
            exit 1
        }

        Write-ColorOutput "Installing watcher (requires admin privileges)..." "Yellow"
        Start-Process pwsh.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$InstallScript`"" -Verb RunAs -Wait

        Start-Sleep -Seconds 1
        Get-WatcherStatus
    }

    "Uninstall" {
        if (-not (Test-Path $InstallScript)) {
            Write-ColorOutput "ERROR: Install script not found: $InstallScript" "Red"
            exit 1
        }

        Write-ColorOutput "Uninstalling watcher (requires admin privileges)..." "Yellow"
        Start-Process pwsh.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$InstallScript`" -Uninstall" -Verb RunAs -Wait
    }
}

exit 0
