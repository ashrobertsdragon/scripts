#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Compiles Protocol Buffer (.proto) files to Python code.

.DESCRIPTION
    This script compiles .proto files into Python code using the gRPC tools. It prompts the user for the directory containing the .proto files, cleans up old generated files, compiles the .proto files, and moves the generated stub files to a 'stubs' directory.

.PARAMETER ProtoDir
    The path to the directory containing the .proto files, relative to the project root.

.EXAMPLE
    PS C:\> .\protobuf-compile.ps1
    Enter the path to the directory containing .proto files, relative to project root (shoulld be current location) (default: .): protos
#>
param(
    [string]$ProtoDir = "."
)

function Read-InputWithDefault($prompt, $default) {
    $userInput = Read-Host -Prompt "$prompt (default: $default)"
    if ([string]::IsNullOrWhiteSpace($userInput)) {
        return $default
    } else {
        return $userInput
    }
}

function Find-FullPath($userPath) {
    if ([System.IO.Path]::IsPathRooted($userPath)) {
        # If user provided a full path, it is unusable
        Write-Host "Error: Must use a relative path"
        exit
    }
    $fullPath = Join-Path -Path $PWD -ChildPath $userPath
    if (-not (Test-Path -Path $fullPath -PathType Container)) {
        Write-Host "Error: The specified directory does not exist or is not accessible."
        exit
    } 
    return $fullPath
}

function Create-PyPath($winPath) {
    $pyPath = $winPath -replace "\\", "/"
    return $PyPath.TrimStart("./")
}

function Remove-OldFiles($path, $filter) {
    if (Test-Path $path) {
        $files = Get-ChildItem -Path $path -Filter $filter
        foreach ($file in $files) {
            Remove-Item $file -Force
            Write-Host "Deleted $file"
        }
    }
}

function Compile-ProtoFiles($fullPath, $userDir) {
    $protoFiles = Get-ChildItem -Path $fullPath -Filter "*.proto"
    $importPath = Create-PyPath $userDir
    
    if ($protoFiles.Count -eq 0) {
        Write-Host "No .proto files found in the specified directory."
        exit
    }
    Write-Host "full path:" $fullPath
    Write-Host "import path" $importPath
    foreach ($protoFile in $protoFiles) {
        Write-Host "Compiling $($protoFile.Name)..."
        & python -m grpc_tools.protoc `
            -I"$importPath=$fullPath" `
            --python_out="." `
            --grpc_python_out="." `
            --pyi_out="." `
            "$($protoFile.FullName)"
    }
}

function Move-StubFiles($stubsPath, $fullPath) {
    # All protobuf compiler commands use a path relative to the one supplied in -I, so stub files must be moved
    if (!(Test-Path -Path $stubsPath)) {
        New-Item -ItemType Directory -Path $stubsPath > $null
    }
    Move-Item -Path "$fullPath\*.pyi" -Destination $stubsPath -Force
}

# Should be invoked from Python project root
$userDir = Read-InputWithDefault "Enter the path to the directory containing .proto files, relative to project root (shoulld be current location)" $ProtoDir
$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$fullPath = Find-FullPath $userDir
$stubsPath = Join-Path $PWD "stubs"

# Clean up old files
Remove-OldFiles $fullPath "*_pb2*.py"
Remove-OldFiles $stubsPath "*.pyi"

# Compile and move files
Compile-ProtoFiles $fullPath $userDir
Move-StubFiles $stubsPath $fullPath

Write-Host "Protobuf compilation complete."