#!/bin/bash

# SYNOPSIS
#     Generates a random string of a specified length.
#
# DESCRIPTION
#     This script prompts the user for a desired length and then generates a cryptographically secure random string of that length. The string can contain uppercase letters, lowercase letters, and numbers.
#
# PARAMETERS
#     -l, --length <length>
#         The desired length of the random string.
#
# EXAMPLE
#     ./Create-Key.sh -l 16
#     aR3tGz9kLpQ7wX4e

print_help() {
    echo "Usage: ./Create-Key.sh [options]"
    echo ""
    echo "Generates a random string of a specified length."
    echo ""
    echo "This script prompts the user for a desired length and then generates a cryptographically secure random string of that length. The string can contain uppercase letters, lowercase letters, and numbers."
    echo ""
    echo "Options:"
    echo "  -l, --length <length>  The desired length of the random string"
    echo "  -h, --help             Show this help message and exit"
}

while [[ $# -gt 0 ]]]; do
    key="$1"

    case $key in
        -l|--length)
        LENGTH="$2"
        shift
        shift
        ;;
        -h|--help)
        print_help
        exit 0
        ;;
        *)
        echo "Unknown option: $1"
        print_help
        exit 1
        ;;
    esac
done

if [[ -z "$LENGTH" ]]; then
    read -p "Enter the desired length for the string: " LENGTH
fi

if ! [[ "$LENGTH" =~ ^[0-9]+$ ]]; then
    echo "Invalid input. Please enter a numeric length."
    exit 1
fi

LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "$LENGTH"
echo
