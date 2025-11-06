#!/bin/bash

# SYNOPSIS
#     Restores backup files to their original versions.
#
# DESCRIPTION
#     This script restores one or more files from their backup copies. It looks for backup files with a '.bak' extension, trying two common naming patterns: 'filename.bak' and 'filename.extension.bak'.
#
# PARAMETERS
#     <file1> [file2] ...
#         The path to the file(s) to restore.
#
# EXAMPLE
#     ./Restore-Backup.sh file1.txt file2.log

print_help() {
    echo "Usage: ./Restore-Backup.sh <file1> [file2] ..."
    echo ""
    echo "Restores backup files to their original versions."
    echo ""
    echo "This script restores one or more files from their backup copies. It looks for backup files with a '.bak' extension, trying two common naming patterns: 'filename.bak' and 'filename.extension.bak'."
    echo ""
    echo "Options:"
    echo "  -h, --help   Show this help message and exit"
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    print_help
    exit 0
}

if [ $# -eq 0 ]; then
    echo "[ERROR] No files specified. Please provide one or more files to restore."
    echo "Usage: ./Restore-Backup.sh file1 [file2] [file3] ..."
    exit 1
}

success_count=0
failure_count=0

for file in "$@"; do
    base_name=$(basename "$file" .${file##*.})
    extension=.${file##*.}

    backup_file1="$base_name.bak"
    backup_file2="$file.bak"

    if [ -f "$backup_file1" ]; then
        cp -f "$backup_file1" "$file"
        echo "[SUCCESS] Successfully restored $backup_file1 to $file"
        ((success_count++))
    elif [ -f "$backup_file2" ]; then
        cp -f "$backup_file2" "$file"
        echo "[SUCCESS] Successfully restored $backup_file2 to $file"
        ((success_count++))
    else
        echo "[ERROR] Backup file for $file does not exist"
        ((failure_count++))
    fi
done

echo -e "\nRestore Summary:"
if [ $failure_count -eq 0 ]; then
    echo "[SUCCESS] All $success_count files restored successfully!"
else
    echo "[WARNING] $success_count files were restored, but $failure_count failed. Check messages above."
fi
