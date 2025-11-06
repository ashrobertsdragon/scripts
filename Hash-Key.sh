#!/bin/bash

# SYNOPSIS
#     Hashes a key with an optional salt using SHA256.
#
# DESCRIPTION
#     This script prompts the user for a key and an optional salt, concatenates them, and then computes the SHA256 hash of the combined string. The resulting hash is printed to the console.
#
# EXAMPLE
#     ./Hash-Key.sh
#     Enter the key to be hashed: mysecretkey
#     Enter the salt: mysalt
#     f2c2b828c23a28e6a28a9a1f2a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a

print_help() {
    echo "Usage: ./Hash-Key.sh"
    echo ""
    echo "Hashes a key with an optional salt using SHA256."
    echo ""
    echo "This script prompts the user for a key and an optional salt, concatenates them, and then computes the SHA256 hash of the combined string. The resulting hash is printed to the console."
    echo ""
    echo "Options:"
    echo "  -h, --help   Show this help message and exit"
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    print_help
    exit 0
fi

read -p "Enter the key to be hashed: " key
read -p "Enter the salt: " salt

combined="$key$salt"

echo -n "$combined" | sha256sum | awk '{print $1}'
