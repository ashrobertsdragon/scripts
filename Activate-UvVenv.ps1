#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Creates a Python virtual environment and activates it.

.DESCRIPTION
    This script creates a Python 3.12 virtual environment named '.venv' in the current directory, activates it, and then synchronizes the environment with the requirements specified in the project's pyproject.toml file, including all optional dependencies.

.EXAMPLE
    PS C:\> .\uv-activate-venv.ps1
#>

uv venv --python 3.12
& .\.venv\Scripts\Activate.ps1
uv sync --all-extras