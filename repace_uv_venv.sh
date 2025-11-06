#!/bin/bash

# SYNOPSIS
#     Replaces the Python virtual environment.
#
# DESCRIPTION
#     This script automates the process of replacing the Python virtual environment (.venv). It can handle multiple instances of Visual Studio Code, prompting the user to select the correct one if necessary. It closes the selected VS Code instance, deletes the existing .venv folder, creates a new one, and then reopens the original folder in VS Code.
#
# EXAMPLE
#     ./uv-replace-venv.sh

print_help() {
    echo "Usage: ./uv-replace-venv.sh"
    echo ""
    echo "Replaces the Python virtual environment."
    echo ""
    echo "This script automates the process of replacing the Python virtual environment (.venv). It can handle multiple instances of Visual Studio Code, prompting the user to select the correct one if necessary. It closes the selected VS Code instance, deletes the existing .venv folder, creates a new one, and then reopens the original folder in VS Code."
    echo ""
    echo "Options:"
    echo "  -h, --help   Show this help message and exit"
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    print_help
    exit 0
fi

close_vscode() {
    local pid=$1
    # This is a placeholder. A more robust solution would be needed to gracefully close VS Code on Linux/macOS.
    echo "Closing VS Code (PID: $pid)..."
    kill "$pid"
}

open_vscode() {
    local folder_path=$1
    if [ -n "$folder_path" ]; then
        code "$folder_path"
    else
        echo "No folder path found to re-open in VSCode."
    fi
}

delete_venv_folder() {
    if [ -d ".venv" ]; then
        rm -rf .venv
        echo ".venv directory deleted successfully."
    else
        echo "No .venv directory found in the current working directory."
    fi
}

run_uv_venv() {
    ./uv-activate-venv.sh
}

select_vscode_instance() {
    local pids=($(pgrep -f "/usr/share/code/code"))

    if [ ${#pids[@]} -gt 1 ]; then
        echo "Multiple VSCode instances found:"
        ps -o pid,args -p "${pids[@]}"
        read -p "Enter the Process ID (PID) of the instance you want to target: " selected_pid
    elif [ ${#pids[@]} -eq 1 ]; then
        selected_pid=${pids[0]}
    else
        echo "No VSCode instances are running."
        delete_venv_folder
        run_uv_venv
        return
    fi

    local folder_path=$(ps -o args -p "$selected_pid" | tail -n 1)
    close_vscode "$selected_pid"
    echo "$folder_path"
}

recreate_venv() {
    delete_venv_folder
    run_uv_venv
}

folder_path=$(select_vscode_instance)
recreate_venv
open_vscode "$folder_path"
