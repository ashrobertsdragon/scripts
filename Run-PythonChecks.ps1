#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Runs a series of quality checks on the codebase.

.DESCRIPTION
    This script ensures the codebase meets quality standards by running a series of checks. It initializes a quality checking tool (qlty), configures it, and then runs a sequence of commands including linting, formatting, and type checking.

.EXAMPLE
    PS C:\> .\Rub-ADubDub.ps1
#>

function Assert-Success {
    param(
        [int]$Code = $LASTEXITCODE,
        [string]$Context = "Previous command"
    )

    if ($Code -ne 0) {
        Write-Error "$Context failed with exit code $Code"
        exit $Code
    }
}

$tomlPath = ".qlty\qlty.toml"
$markdownlintPath = ".qlty\configs\.markdownlint.jsonc"

# Check if .qlty directory exists
if (!(Test-Path ".qlty" -PathType Container)) {
    Write-Host "Initializing qlty..."
    
    # Run qlty init and pipe "no" to answer prompts
    qlty init --no
    Assert-Success -Context "qlty init"

    # Edit qlty.toml t
    $lines = Get-Content $tomlPath
    $i = ($lines | Select-String '^\s*\]' | Select -First 1).LineNumber - 1
    $lines = $lines[0..($i-1)] + '  "**/tests/**",' + $lines[$i..($lines.Count - 1)]
    $lines | Set-Content $tomlPath
}

$content = Get-Content $tomlPath -Raw
if (-not $content.Contains('**/tests/**')) {
    Write-Host "Tests path missing from qlty.toml"
    exit 1
}

if ($content -match '\bruff\b') {
    qlty plugins disable ruff
    Assert-Success -Context "Disabling ruff plugin"
}
if ($content -match '\bmarkdownlint\b') {
    qlty plugins disable markdownlint
    Assert-Success -Context "Disabling markdownlint plugin"
}

$commands = @(
    "uvx ruff check --fix .",
    "uvx ruff format",
    "qlty check --all --no-formatters --fix --fail-level=low",
    "uvx mypy .",
    "uvx ruff check --fix .",
    "uvx ruff format"
)

foreach ($command in $commands) {
    Write-Host "`nRunning: $command" -ForegroundColor Cyan
    Invoke-Expression $command
    Assert-Success -Context $command
}

Write-Host "`nAll quality checks completed successfully!" -ForegroundColor Green