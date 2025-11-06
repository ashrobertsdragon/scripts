#!/bin/bash

# SYNOPSIS
#     Creates Docker secrets from a .env file.
#
# DESCRIPTION
#     This script reads key-value pairs from a .env file in the current directory and creates individual files for each key in a 'docker_secrets' subdirectory. Each file is named after the key and contains the corresponding value.
#
# PARAMETERS
#     EnvPath
#         The path to the .env file.
#
#     SecretsDir
#         The path to the directory where the secret files will be created.
#
# EXAMPLE
#     ./Create-DockerSecrets.sh
#     This command reads the .env file in the current directory and creates Docker secrets in the './docker_secrets' directory.

print_help() {
    echo "Usage: ./Create-DockerSecrets.sh [options]"
    echo ""
    echo "Creates Docker secrets from a .env file."
    echo ""
    echo "This script reads key-value pairs from a .env file in the current directory and creates individual files for each key in a 'docker_secrets' subdirectory. Each file is named after the key and contains the corresponding value."
    echo ""
    echo "Options:"
    echo "  --env-path <path>      The path to the .env file (default: ./.env)"
    echo "  --secrets-dir <path>   The path to the directory where the secret files will be created (default: ./docker_secrets)"
    echo "  -h, --help             Show this help message and exit"
}

ENV_PATH="./.env"
SECRETS_DIR="./docker_secrets"

while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        --env-path)
        ENV_PATH="$2"
        shift
        shift
        ;;
        --secrets-dir)
        SECRETS_DIR="$2"
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

mkdir -p "$SECRETS_DIR"

while IFS= read -r line; do
    if [[ -z "$line" || "$line" == #* ]]; then
        continue
    fi

    key=$(echo "$line" | cut -d '=' -f 1)
    value=$(echo "$line" | cut -d '=' -f 2-)

    echo "$value" > "$SECRETS_DIR/.$key"
done < "$ENV_PATH"
