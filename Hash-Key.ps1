#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Hashes a key with an optional salt using SHA256.

.DESCRIPTION
    This script prompts the user for a key and an optional salt, concatenates them, and then computes the SHA256 hash of the combined string. The resulting hash is printed to the console.

.EXAMPLE
    PS C:\> .\Hash-Key.ps1
    Enter the key to be hashed: mysecretkey
    Enter the salt: mysalt
    f2c2b828c23a28e6a28a9a1f2a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a
#>

function Read-Input($keyPrompt, $saltPrompt) {
    $keyInput = Read-Host -Prompt "$keyPrompt"
    $saltInput = Read-Host -Prompt "$saltPrompt"
    if ([string]::IsNullOrWhiteSpace($saltPrompt)) {
        return $keyInput
    } else {
        return $keyInput + $saltInput
    }
}

$keyPrompt = "Enter the key to be hashed"
$saltPrompt = "Enter the salt"

$key = Read-Input $keyPrompt $saltPrompt

$sha256 = [System.Security.Cryptography.SHA256]::Create()
$hashBytes = $sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($key))

$hashedKey = -join ($hashBytes | ForEach-Object { "{0:x2}" -f $_ })
Write-Host $hashedKey
