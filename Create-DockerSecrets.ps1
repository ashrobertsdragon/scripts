#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Creates Docker secrets from a .env file.

.DESCRIPTION
    This script reads key-value pairs from a .env file in the current directory and creates individual files for each key in a 'docker_secrets' subdirectory. Each file is named after the key and contains the corresponding value.

.PARAMETER EnvPath
    The path to the .env file.

.PARAMETER SecretsDir
    The path to the directory where the secret files will be created.

.EXAMPLE
    PS C:\> .\Create-DockerSecrets.ps1
    This command reads the .env file in the current directory and creates Docker secrets in the './docker_secrets' directory.
#>
param(
    [string]$EnvPath = './.env',
    [string]$SecretsDir = './docker_secrets'
)

if (!(Test-Path -Path $SecretsDir)) {
    New-Item -ItemType Directory -Path $SecretsDir | Out-Null
}

Get-Content -Path $EnvPath | ForEach-Object {
    if ($_ -match "^\s*$" -or $_ -match "^\s*#") {
        continue
    }

    $key, $value = $_ -split '=', 2
    $key = $key.Trim()
    $value = $value.Trim()

    Set-Content -Path "$SecretsDir/.$key" -Value $value
}