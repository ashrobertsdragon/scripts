#Requires -Version 5.1

<#
.SYNOPSIS
    Continuously monitors MCP server configuration files and triggers synchronization on changes.

.DESCRIPTION
    This script runs as a persistent background process that watches:
    - The main mcp-servers.json file for changes
    - The ccmcp-config directory for added/removed/modified JSON files
    When changes are detected, it automatically triggers the sync script.

.PARAMETER MainConfigPath
    Path to the main mcp-servers.json file. Default: C:\Users\ashro\.mcp-servers\mcp-servers.json

.PARAMETER ConfigDirectory
    Path to the directory containing individual config files. Default: C:\Users\ashro\.mcp-servers\ccmcp-config

.PARAMETER SyncScriptPath
    Path to the sync script. Default: Same directory as this script

.PARAMETER DebounceMilliseconds
    Milliseconds to wait after last change before triggering sync. Default: 2000

.EXAMPLE
    .\Watch-MCPServers.ps1
    
.EXAMPLE
    .\Watch-MCPServers.ps1 -DebounceMilliseconds 5000
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$MainConfigPath = "C:\Users\ashro\.mcp-servers\mcp-servers.json",
    
    [Parameter()]
    [string]$ConfigDirectory = "C:\Users\ashro\.mcp-servers\ccmcp-configs",
    
    [Parameter()]
    [string]$SyncScriptPath = "",
    
    [Parameter()]
    [int]$DebounceMilliseconds = 2000
)

if ([string]::IsNullOrEmpty($SyncScriptPath)) {
    $SyncScriptPath = Join-Path $PSScriptRoot "Sync-MCPServers.ps1"
}

$script:lastSyncTime = [DateTime]::MinValue
$script:logFile = "$env:TEMP\watch-mcp-debug.log"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    Write-Host $Message -ForegroundColor $Color
}

function Invoke-Sync {
    param(
        [string]$Reason
    )

    $timeSinceLastSync = (Get-Date) - $script:lastSyncTime

    if ($timeSinceLastSync.TotalMilliseconds -lt $DebounceMilliseconds) {
        return
    }

    try {
        "$(Get-Date) - [$Reason] Triggering sync..." | Out-File $script:logFile -Append
        & $SyncScriptPath -MainConfigPath $MainConfigPath -ConfigDirectory $ConfigDirectory
        $script:lastSyncTime = Get-Date
        "$(Get-Date) - [$Reason] Sync completed" | Out-File $script:logFile -Append
    }
    catch {
        "$(Get-Date) - ERROR during sync: $_" | Out-File $script:logFile -Append
    }
}

function Start-FileWatcher {
    "$(Get-Date) - Start-FileWatcher called" | Out-File $script:logFile -Append

    if (-not (Test-Path $SyncScriptPath)) {
        "$(Get-Date) - ERROR: Sync script not found: $SyncScriptPath" | Out-File $script:logFile -Append
        return
    }

    if (-not (Test-Path $MainConfigPath)) {
        "$(Get-Date) - ERROR: Main config not found: $MainConfigPath" | Out-File $script:logFile -Append
        return
    }

    if (-not (Test-Path $ConfigDirectory)) {
        New-Item -ItemType Directory -Path $ConfigDirectory -Force | Out-Null
    }

    $mainConfigDir = Split-Path $MainConfigPath -Parent
    $mainConfigFileName = Split-Path $MainConfigPath -Leaf

    $mainWatcher = New-Object System.IO.FileSystemWatcher
    $mainWatcher.Path = $mainConfigDir
    $mainWatcher.Filter = $mainConfigFileName
    $mainWatcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite
    $mainWatcher.EnableRaisingEvents = $true

    $directoryWatcher = New-Object System.IO.FileSystemWatcher
    $directoryWatcher.Path = $ConfigDirectory
    $directoryWatcher.Filter = "*.json"
    $directoryWatcher.NotifyFilter = [System.IO.NotifyFilters]::FileName -bor [System.IO.NotifyFilters]::LastWrite
    $directoryWatcher.EnableRaisingEvents = $true

    $null = Register-ObjectEvent -InputObject $mainWatcher -EventName Changed -SourceIdentifier "MainConfigChanged"
    $null = Register-ObjectEvent -InputObject $directoryWatcher -EventName Changed -SourceIdentifier "DirConfigChanged"
    $null = Register-ObjectEvent -InputObject $directoryWatcher -EventName Created -SourceIdentifier "DirConfigCreated"
    $null = Register-ObjectEvent -InputObject $directoryWatcher -EventName Deleted -SourceIdentifier "DirConfigDeleted"
    $null = Register-ObjectEvent -InputObject $directoryWatcher -EventName Renamed -SourceIdentifier "DirConfigRenamed"

    "$(Get-Date) - Watchers started successfully" | Out-File $script:logFile -Append
    "$(Get-Date) - Main config: $MainConfigPath" | Out-File $script:logFile -Append
    "$(Get-Date) - Config directory: $ConfigDirectory" | Out-File $script:logFile -Append

    # Perform initial sync on startup
    Invoke-Sync -Reason "Initial sync on startup"

    try {
        while ($true) {
            $event = Wait-Event -Timeout 1

            if ($event) {
                $eventName = $event.SourceIdentifier
                "$(Get-Date) - Event received: $eventName" | Out-File $script:logFile -Append
                Remove-Event -EventIdentifier $event.EventIdentifier

                switch -Regex ($eventName) {
                    "MainConfig" {
                        Invoke-Sync -Reason "Main config changed"
                    }
                    "DirConfig" {
                        Invoke-Sync -Reason "Config directory changed"
                    }
                }
            }
        }
    }
    finally {
        "$(Get-Date) - Cleaning up watchers" | Out-File $script:logFile -Append

        Get-EventSubscriber | Where-Object {
            $_.SourceIdentifier -match "MainConfig|DirConfig"
        } | Unregister-Event

        Get-Event | Where-Object {
            $_.SourceIdentifier -match "MainConfig|DirConfig"
        } | Remove-Event

        $mainWatcher.EnableRaisingEvents = $false
        $directoryWatcher.EnableRaisingEvents = $false
        $mainWatcher.Dispose()
        $directoryWatcher.Dispose()
    }
}

Start-FileWatcher
exit 0