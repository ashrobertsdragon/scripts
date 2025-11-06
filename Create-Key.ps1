#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Generates a random string of a specified length.

.DESCRIPTION
    This script prompts the user for a desired length and then generates a cryptographically secure random string of that length. The string can contain uppercase letters, lowercase letters, and numbers.

.PARAMETER Length
    The desired length of the random string.

.EXAMPLE
    PS C:\> .\Create-Key.ps1
    Enter the desired length for the string: 16
    aR3tGz9kLpQ7wX4e
#>
param(
    [Parameter(Mandatory=$true)]
    [int]$Length
)

Add-Type -AssemblyName System.Security

$chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
$charArray = $chars.ToCharArray()
$randomString = ""

# Create a secure random generator
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$randomBytes = New-Object byte[] 1  # We only need 1 byte at a time

for ($i = 0; $i -lt $Length; $i++) {
    # Generate a random index within the bounds of the character array
    $rng.GetBytes($randomBytes)
    $index = $randomBytes[0] % $charArray.Length
    $randomString += $charArray[$index]
}

Write-Host $randomString
