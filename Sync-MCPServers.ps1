#Requires -Version 5.1

<#
.SYNOPSIS
    Synchronizes MCP server configurations between a main JSON file and individual configuration files.

.DESCRIPTION
    This script performs bi-directional synchronization:
    - Creates individual JSON files for entries in mcp-servers.json that don't have corresponding files
    - Adds entries to mcp-servers.json for JSON files that don't have corresponding entries
    - Maintains alphabetical sorting in mcp-servers.json
    - Only syncs missing entries; does not compare or update existing configurations

.PARAMETER MainConfigPath
    Path to the main mcp-servers.json file. Default: C:\Users\ashro\.mcp-servers\mcp-servers.json

.PARAMETER ConfigDirectory
    Path to the directory containing individual config files. Default: C:\Users\ashro\.mcp-servers\ccmcp-config

.EXAMPLE
    .\Sync-MCPServers.ps1
    
.EXAMPLE
    .\Sync-MCPServers.ps1 -MainConfigPath "C:\custom\path\mcp-servers.json" -ConfigDirectory "C:\custom\path\configs"
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$MainConfigPath = "C:\Users\ashro\.mcp-servers\mcp-servers.json",
    
    [Parameter()]
    [string]$ConfigDirectory = "C:\Users\ashro\.mcp-servers\ccmcp-configs"
)

function Convert-ToSnakeCase {
    param([string]$Text)
    
    return $Text -replace '[-.]', '_'
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "Red"
    )
    
    Write-Host $Message -ForegroundColor $Color
}

function Sync-McpConfigurations {
    if (-not (Test-Path $MainConfigPath)) {
        Write-ColorOutput "ERROR: Main config file not found: $MainConfigPath" "Red"
        return
    }
    
    if (-not (Test-Path $ConfigDirectory)) {
        New-Item -ItemType Directory -Path $ConfigDirectory -Force | Out-Null
    }
    
    try {
        $mainConfig = Get-Content $MainConfigPath -Raw | ConvertFrom-Json
    }
    catch {
        Write-ColorOutput "ERROR: Failed to parse main config file: $_" "Red"
        return
    }
    
    if (-not $mainConfig.mcpServers) {
        Write-ColorOutput "ERROR: Main config file missing 'mcpServers' key" "Red"
        return
    }
    
    $mainServers = $mainConfig.mcpServers
    $mainKeys = $mainServers.PSObject.Properties.Name
    
    $configFiles = Get-ChildItem -Path $ConfigDirectory -Filter "*.json" -File
    $existingFileKeys = @{}
    
    foreach ($file in $configFiles) {
        $nameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        
        # Try both dash and dot variants when converting from snake_case
        $keyVariants = @(
            ($nameWithoutExt -replace '_', '-')
            ($nameWithoutExt -replace '_', '.')
        )
        
        $foundKey = $null
        foreach ($variant in $keyVariants) {
            if ($variant -in $mainKeys) {
                $foundKey = $variant
                break
            }
        }
        
        if ($foundKey) {
            $existingFileKeys[$foundKey] = $file.FullName
        }
        else {
            # File exists but key not in main config - need to read it to add
            try {
                $fileConfig = Get-Content $file.FullName -Raw | ConvertFrom-Json
                if ($fileConfig.mcpServers) {
                    $keys = @($fileConfig.mcpServers.PSObject.Properties.Name)
                    if ($keys.Count -eq 1) {
                        $key = $keys[0]
                        $existingFileKeys[$key] = $file.FullName
                    }
                }
            }
            catch {
                # Skip files that can't be parsed
            }
        }
    }
    
    $changesMade = $false
    
    foreach ($key in $mainKeys) {
        if (-not $existingFileKeys.ContainsKey($key)) {
            $snakeCaseKey = Convert-ToSnakeCase $key
            $fileName = "$snakeCaseKey.json"
            $filePath = Join-Path $ConfigDirectory $fileName
            
            $individualConfig = @{
                mcpServers = @{
                    $key = $mainServers.$key
                }
            }

            $individualConfig | ConvertTo-Json -Depth 5 -Compress | jq | Set-Content -Path $filePath -Encoding UTF8NoBOM
            $changesMade = $true
        }
    }
    
    $entriesToAdd = @{}
    
    foreach ($key in $existingFileKeys.Keys) {
        if ($key -notin $mainKeys) {
            $filePath = $existingFileKeys[$key]
            
            try {
                $fileConfig = Get-Content $filePath -Raw | ConvertFrom-Json
                
                if ($fileConfig.mcpServers -and $fileConfig.mcpServers.PSObject.Properties.Name -contains $key) {
                    $entriesToAdd[$key] = $fileConfig.mcpServers.$key
                }
            }
            catch {
                Write-ColorOutput "ERROR: Skipping $(Split-Path $filePath -Leaf): Parse error - $_" "Red"
            }
        }
    }
    
    if ($entriesToAdd.Count -gt 0) {
        foreach ($key in $entriesToAdd.Keys) {
            $mainServers | Add-Member -MemberType NoteProperty -Name $key -Value $entriesToAdd[$key]
        }
        
        $sortedServers = [ordered]@{}
        $mainServers.PSObject.Properties.Name | Sort-Object | ForEach-Object {
            $sortedServers[$_] = $mainServers.$_
        }

        $mainConfig.mcpServers = [PSCustomObject]$sortedServers

        $mainConfig | ConvertTo-Json -Depth 5 -Compress | jq | Set-Content -Path $MainConfigPath -Encoding UTF8NoBOM
        $changesMade = $true
    }
}

Sync-McpConfigurations
exit 0