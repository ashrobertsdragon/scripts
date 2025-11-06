#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Generates a random, secure password of a specified length.

.DESCRIPTION
    This script prompts the user for a desired length and then generates a cryptographically secure, Base64-encoded random string of that length.

.PARAMETER Length
    The desired length of the password.

.EXAMPLE
    PS C:\> .\Create-Password.ps1
    Enter the desired length for the string: 12
    aB3/dE5+gH7i
#>
param(
    [Parameter(Mandatory=$true)]
    [int]$Length
)

Add-Type -AssemblyName System.Security

$randomBytes = New-Object byte[] ([math]::Ceiling($Length / 4 * 3))
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($randomBytes)
$secureString = [Convert]::ToBase64String($randomBytes).Substring(0, $Length)
Write-Host $secureString
