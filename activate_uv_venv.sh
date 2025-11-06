#!/bin/bash

# SYNOPSIS
#     Creates a Python virtual environment and activates it.
#
# DESCRIPTION
#     This script creates a Python 3.12 virtual environment named '.venv' in the current directory, activates it, and then synchronizes the environment with the requirements specified in the project's pyproject.toml file, including all optional dependencies.
#
# EXAMPLE
#     ./uv-activate-venv.sh

print_help() {
    echo "Usage: ./uv-activate-venv.sh"
    echo ""
    echo "Creates a Python virtual environment and activates it."
    echo ""
    echo "This script creates a Python 3.12 virtual environment named '.venv' in the current directory, activates it, and then synchronizes the environment with the requirements specified in the project's pyproject.toml file, including all optional dependencies."
    echo ""
    echo "Options:"
    echo "  -h, --help   Show this help message and exit"
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    print_help
    exit 0
fi

uv venv --python 3.12
source ./.venv/bin/activate
uv sync --all-extras
