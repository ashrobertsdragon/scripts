# Personal scripts Collection

A collection of utility scripts for development workflows, system administration, and automation tasks.

## Table of Contents

- [Python Environment Management](#python-environment-management)
- [Docker & Containerization](#docker--containerization)
- [Security & Cryptography](#security--cryptography)
- [MCP Configuration Management](#mcp-configuration-management)
- [Protocol Buffers](#protocol-buffers)
- [Data Processing](#data-processing)
- [Code Quality & Formatting](#code-quality--formatting)
- [Miscellaneous Utilities](#miscellaneous-utilities)

## Python Environment Management

### Activate-UvVenv.ps1 / activate_uv_venv.sh

Creates and activates a Python virtual environment using `uv`.

```powershell
.\Activate-UvVenv.ps1
```

```bash
./activate_uv_venv.sh
```

### Replace-UvVenv.ps1 / repace_uv_venv.sh

Replaces the existing virtual environment. Handles VS Code instances automatically.

```powershell
.\Replace-UvVenv.ps1
```

```bash
./repace_uv_venv.sh
```

## Docker & Containerization

### Create-DockerSecrets.ps1 / create_docker_secrets.sh

Creates Docker secret files from a `.env` file.

```powershell
.\Create-DockerSecrets.ps1 [-EnvPath <path>] [-SecretsDir <path>]
```

```bash
./create_docker_secrets.sh [--env-path <path>] [--secrets-dir <path>]
```

### start_docker_sandbox.py

Builds and runs a development sandbox container with optional source mounting and package installation.

```bash
python start_docker_sandbox.py [--local-dir <path>] [--github-repo <url>]
    [--node-packages <packages>] [--initial-command <cmd>]
    [--command {bash,vscode}] [--dockerfile-dir <path>]
```

## Security & Cryptography

### Create-Key.ps1 / create_key.sh

Generates a cryptographically secure random string.

```powershell
.\Create-Key.ps1 -Length <number>
```

```bash
./create_key.sh -l <number>
```

### Create-Password.ps1 / create_password.sh

Generates a Base64-encoded secure password.

```powershell
.\Create-Password.ps1 -Length <number>
```

```bash
./create_password.sh -l <number>
```

### Hash-Key.ps1 / Hash-Key.sh / hash_key.sh

Computes SHA256 hash of a key with optional salt.

```powershell
.\Hash-Key.ps1
```

```bash
./Hash-Key.sh
```

### create_cert.py

Creates a self-signed SSL certificate and private key.

```bash
python create_cert.py
```

## MCP Configuration Management

### Sync-MCPServers.ps1

Synchronizes MCP server configurations bidirectionally between main config and individual files.

```powershell
.\Sync-MCPServers.ps1 [-MainConfigPath <path>] [-ConfigDirectory <path>]
```

### Watch-MCPServers.ps1

Continuously monitors MCP configuration files and triggers sync on changes.

```powershell
.\Watch-MCPServers.ps1 [-MainConfigPath <path>] [-ConfigDirectory <path>]
    [-SyncScriptPath <path>] [-DebounceMilliseconds <ms>]
```

### Install-MCPWatcher.ps1

Installs or uninstalls the MCP watcher as a Windows Scheduled Task.

```powershell
.\Install-MCPWatcher.ps1 [-Uninstall]
```

### Manage-MCPWatcher.ps1

Manages the MCP watcher scheduled task.

```powershell
.\Manage-MCPWatcher.ps1 -Action {Start|Stop|Restart|Status|Logs|Install|Uninstall}
```

## Protocol Buffers

### Compile-Protobuf.ps1 / compile_protobuf.sh

Compiles `.proto` files to Python code using gRPC tools.

```powershell
.\Compile-Protobuf.ps1 [-ProtoDir <path>]
```

```bash
./compile_protobuf.sh [-d <path>]
```

## Data Processing

### aggregate_spending_csv.py

Analyzes spending from a CSV file and aggregates monthly totals.

```bash
python aggregate_spending_csv.py <filepath> [keyword] [date_format]
```

### clean_json.py

Sorts JSON keys and expands dot notation into nested objects.

```bash
python clean_json.py {-f <file> | -s <string> | -i}
    [-v | -vv] [-q] [-l <logfile>]
```

### convert_PS_table.py

Converts PowerShell table output to JSON format.

```bash
python convert_PS_table.py <zone_file> <output_file>
```

### convert_fitbit.py

Converts Fitbit export data to formats compatible with other health apps.

```bash
python convert_fitbit.py <fitbit_path> [export_path]
    [-s <YYYY-M-D>] [-e <YYYY-M-D>] [-v | -vv] [-l <logfile>]
```

### parse_tz_data.py

Parses IANA timezone database and outputs zone offsets as JSON.

```bash
python parse_tz_data.py [-o <output>] {-d <dir> | -u <url>}
    [-v | -vv | -q] [-l <logfile>]
```

## Code Quality & Formatting

### Run-PythonChecks.ps1 / run_python_checks.sh

Runs linting, formatting, and type checking on Python codebase.

```powershell
.\Run-PythonChecks.ps1
```

```bash
./run_python_checks.sh
```

### format_markdown_files.py

Formats all markdown files in a directory tree.

```bash
python format_markdown_files.py
```

## Miscellaneous Utilities

### Restore-Backup.ps1 / restore_backup.sh

Restores files from `.bak` backup copies.

```powershell
.\Restore-Backup.ps1 <file1> [file2] ...
```

```bash
./restore_backup.sh <file1> [file2] ...
```

### LOAD_ENVS.bat

Loads environment variables from a `.env` file, walking up directory tree.

```batch
LOAD_ENVS.bat <envfile> [stop_marker | --all]
```

### playlist_creator.py

Creates YouTube Music playlists from text files.

```bash
python playlist_creator.py <title> <description> <playlist-file>
    [--privacy {PUBLIC|PRIVATE}]
```

### Restart-ChromeVM.ps1

Taints and recreates a Chrome VM in Terraform.

```powershell
.\Restart-ChromeVM.ps1
```

## Requirements

- PowerShell 5.1+ (Windows scripts)
- Bash (Linux/macOS scripts)
- Python 3.10+ (Python scripts)
- Docker (container scripts)
- `uv` package manager (Python environment scripts)
- `qlty` tool (code quality scripts)

## Notes

- Scripts with both `.ps1` and `.sh` versions provide cross-platform functionality
- Most scripts include help with `-h` or `--help` flag
- Python scripts use type annotations (3.10+ style)
- Many scripts support verbosity levels with `-v` and `-vv` flags
