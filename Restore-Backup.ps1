#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Restores backup files to their original versions.

.DESCRIPTION
    This script restores one or more files from their backup copies. It looks for backup files with a '.bak' extension, trying two common naming patterns: 'filename.bak' and 'filename.extension.bak'.

.PARAMETER File
    The path to the file(s) to restore.

.EXAMPLE
    PS C:\> .\Restore-Backup.ps1 file1.txt file2.log
#>
param(
    [Parameter(Mandatory=$true)]
    [string[]]$File
)

# restore-backups.ps1
# Script to restore backup files to their original versions

# Set error action preference to stop execution on any error
$ErrorActionPreference = "Stop"

function Restore-Backup {
    param (
        [string]$BackupFile,
        [string]$TargetFile
    )

    try {
        if (Test-Path $BackupFile) {
            Copy-Item -Path $BackupFile -Destination $TargetFile -Force
            Write-Host "[SUCCESS] Successfully restored $BackupFile to $TargetFile" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[ERROR] Backup file $BackupFile does not exist" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host ("[ERROR] Failed to restore " + ${BackupFile} + " to " + ${TargetFile} + ": " + $_.Exception.Message) -ForegroundColor Red
        return $false
    }
}

function Restore-FileWithPatterns {
    param (
        [string]$FileName
    )

    # Get file name and extension
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
    $extension = [System.IO.Path]::GetExtension($FileName)
    
    # Try first pattern: filename.bak
    $backupFile1 = "$baseName.bak"
    $success1 = Restore-Backup -BackupFile $backupFile1 -TargetFile $FileName
    
    # If first pattern failed, try second pattern: filename.extension.bak
    if (-not $success1) {
        $backupFile2 = "$FileName.bak"
        $success2 = Restore-Backup -BackupFile $backupFile2 -TargetFile $FileName
        return $success2
    }
    
    return $success1
}

# Main script execution
Write-Host "Starting backup restoration process..." -ForegroundColor Cyan

# Check if files were provided
if ($File.Count -eq 0) {
    Write-Host "[ERROR] No files specified. Please provide one or more files to restore." -ForegroundColor Red
    Write-Host "Usage: Restore-Backup.ps1 file1 [file2] [file3] ..." -ForegroundColor Yellow
    exit 1
}

# Process each file provided in arguments
$successCount = 0
$failureCount = 0

foreach ($file in $File) {
    $result = Restore-FileWithPatterns -FileName $file
    if ($result) {
        $successCount++
    } else {
        $failureCount++
    }
}

# Provide summary
Write-Host "`nRestore Summary:" -ForegroundColor Cyan
if ($failureCount -eq 0) {
    Write-Host "[SUCCESS] All $successCount files restored successfully!" -ForegroundColor Green
} elseif ($successCount -gt 0) {
    Write-Host "[WARNING] $successCount files were restored, but $failureCount failed. Check messages above." -ForegroundColor Yellow
} else {
    Write-Host "[ERROR] Failed to restore any files. Check messages above." -ForegroundColor Red
}
