#!/bin/bash

# SYNOPSIS
#     Generates a random, secure password of a specified length.
#
# DESCRIPTION
#     This script prompts the user for a desired length and then generates a cryptographically secure, Base64-encoded random string of that length.
#
# PARAMETERS
#     -l, --length <length>
#         The desired length of the random string.
#
# EXAMPLE
#     ./Create-Password.sh -l 12
#     aB3/dE5+gH7i

print_help() {
    echo "Usage: ./Create-Password.sh [options]"
    echo ""
    echo "Generates a random, secure password of a specified length."
    echo ""
    echo "This script prompts the user for a desired length and then generates a cryptographically secure, Base64-encoded random string of that length."
    echo ""
    echo "Options:"
    echo "  -l, --length <length>  The desired length of the password"
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

openssl rand -base64 "$LENGTH" | head -c "$LENGTH"
echo
