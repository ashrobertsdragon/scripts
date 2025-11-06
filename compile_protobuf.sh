#!/bin/bash

# SYNOPSIS
#     Compiles Protocol Buffer (.proto) files to Python code.
#
# DESCRIPTION
#     This script compiles .proto files into Python code using the gRPC tools. It prompts the user for the directory containing the .proto files, cleans up old generated files, compiles the .proto files, and moves the generated stub files to a 'stubs' directory.
#
# PARAMETERS
#     -d, --dir <path>
#         The path to the directory containing the .proto files, relative to the project root.
#
# EXAMPLE
#     ./protobuf-compile.sh -d protos

print_help() {
    echo "Usage: ./protobuf-compile.sh [options]"
    echo ""
    echo "Compiles Protocol Buffer (.proto) files to Python code."
    echo ""
    echo "This script compiles .proto files into Python code using the gRPC tools. It prompts the user for the directory containing the .proto files, cleans up old generated files, compiles the .proto files, and moves the generated stub files to a 'stubs' directory."
    echo ""
    echo "Options:"
    echo "  -d, --dir <path>   The path to the directory containing the .proto files, relative to the project root (default: .)"
    echo "  -h, --help         Show this help message and exit"
}

PROTO_DIR="."

while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        -d|--dir)
        PROTO_DIR="$2"
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

if [ ! -d "$PROTO_DIR" ]; then
    echo "Error: The specified directory does not exist or is not accessible."
    exit 1
fi

STUBS_PATH="stubs"

rm -f "$PROTO_DIR"/*_pb2*.py
rm -f "$STUBS_PATH"/*.pyi

python -m grpc_tools.protoc \
    -I"$PROTO_DIR" \
    --python_out="." \
    --grpc_python_out="." \
    --pyi_out="." \
    "$PROTO_DIR"/*.proto

mkdir -p "$STUBS_PATH"
mv "$PROTO_DIR"/*.pyi "$STUBS_PATH/"

echo "Protobuf compilation complete."
