#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Replaces the Python virtual environment.

.DESCRIPTION
    This script automates the process of replacing the Python virtual environment (.venv). It can handle multiple instances of Visual Studio Code, prompting the user to select the correct one if necessary. It closes the selected VS Code instance, deletes the existing .venv folder, creates a new one, and then reopens the original folder in VS Code.

.EXAMPLE
    PS C:\> .\uv-replace-venv.ps1
#>

function Close-VSCode {
    param ($vscodeProcess)
    
    Add-Type @"
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
"@ -Namespace Win32 -Name User32

    [Win32.User32]::SetForegroundWindow($vscodeProcess.MainWindowHandle)
    
    Start-Sleep -Seconds 1
    code -r --command workbench.action.files.saveAll
    code -r --command workbench.action.closeFolder
    Start-Sleep -Seconds 2
}

function Open-VSCode {
    param ($folderPath)

    if ($folderPath) {
        Start-Process "code" -ArgumentList $folderPath
    } else {
        Write-Host "No folder path found to re-open in VSCode."
    }
}

function Delete-VenvFolder {
    $currentDirectory = Get-Location
    $venvPath = Join-Path -Path $currentDirectory -ChildPath ".venv"

    if (Test-Path $venvPath) {      
        Remove-Item -Path $venvPath -Recurse -Force
        Write-Host ".venv directory deleted successfully."
    } else {
        Write-Host "No .venv directory found in the current working directory."
    }
}

function Run-UvVenv {
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "uv-activate-venv.ps1"

    if (Test-Path $scriptPath) {
        & $scriptPath
    } else {
        Write-Host "uv-activate-venv.ps1 script not found in the script directory."
    }
}

function Select-VSCodeInstance {
    if ($processes.Count -gt 1) {
        Write-Host "Multiple VSCode instances found:"
       
        $processes | ForEach-Object {
            $commandLine = (Get-WmiObject Win32_Process -Filter "ProcessId = $($_.Id)").CommandLine
            Write-Host "$($_.Id) - Opened Folder/File: $commandLine"
        }

        $selectedId = Read-Host "Enter the Process ID (PID) of the instance you want to target"
        $selectedProcess = $processes | Where-Object { $_.Id -eq [int]$selectedId }
    }
    elseif ($processes.Count -eq 1) {
        # Only one VSCode instance is running
        $selectedProcess = $processes | Select-Object -First 1
    }
    else {
        Write-Host "No VSCode instances are running."
        Delete-VenvFolder
        Run-UvVenv
    }
    $folderPath = (Get-WmiObject Win32_Process -Filter "ProcessId = $($selectedProcess.Id)").CommandLine
    Close-VSCode -vscodeProcess $selectedProcess
    return $folderPath
}

function Recreate-Venv {
    Delete-VenvFolder
    Run-UvVenv
}
$processes = Get-Process -Name "Code" -ErrorAction SilentlyContinue
if (-not $processes) {
    Recreate-Venv
}
else
{
    $folderPath = Select-VSCodeInstance
    Recreate-Venv
    Open-VSCode -folderPath $folderPath
}