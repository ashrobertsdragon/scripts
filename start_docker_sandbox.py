#!/usr/bin/env python3

import argparse
import platform
import subprocess
import sys
from enum import Enum
from pathlib import Path


class StartEnvironment(Enum):
    BASH = "bash"
    VSCODE = "code-server --bind-addr 0.0.0.0:8080 --auth none"


DOCKER_IMAGE_NAME = "node-dev-sandbox"

# Common error messages
DOCKER_NOT_FOUND_ERROR = (
    "Docker CLI not found. Please ensure Docker is installed and in your system's PATH."
)


def _get_uv_cache_path() -> Path:
    """Get the UV cache directory path based on the operating system."""
    system = platform.system().lower()
    if system == "windows":
        # Windows: %LOCALAPPDATA%\uv\cache
        localappdata = Path.home() / "AppData" / "Local"
        return localappdata / "uv" / "cache"
    else:
        # Linux/Mac: $HOME/.cache/uv
        return Path.home() / ".cache" / "uv"


def _handle_docker_error(error: subprocess.CalledProcessError, operation: str) -> None:
    """Handle Docker subprocess errors consistently."""
    print(f"Error {operation} (Exit code {error.returncode})")
    if error.stderr:
        print(f"Stderr: {error.stderr.decode()}")
    sys.exit(1)


def _validate_local_directory(local_dir: str) -> Path:
    """Validate and return Path object for local directory."""
    abs_local_dir = Path(local_dir).resolve()
    if not abs_local_dir.is_dir():
        print(f"Error: Local directory '{abs_local_dir}' does not exist.")
        sys.exit(1)
    return abs_local_dir


def _build_base_docker_command() -> list[str]:
    """Build the base Docker run command with common options."""
    uv_cache_path = _get_uv_cache_path()
    return [
        "docker",
        "run",
        "-it",
        "--rm",
        "-p",
        "3000:3000",
        "-p",
        "8080:8080",
        "-v",
        f"{uv_cache_path}:/developer/.cache/uv",
    ]


def _build_full_docker_command(
    image_name: str,
    start_environment: str,
    local_dir: str | None = None,
    github_repo: str | None = None,
    node_packages: str | None = None,
    initial_command: str | None = None,
) -> list[str]:
    docker_command = _build_base_docker_command()
    env_vars: dict[str, str] = {}

    # Handle local directory mounting
    if local_dir:
        env_vars.update(_add_local_directory_mount(docker_command, local_dir))
    # Handle GitHub repository cloning
    elif github_repo:
        env_vars.update(_add_github_repo_env(github_repo))
    else:
        print(
            "No source (local directory or GitHub repo) specified. "
            "Starting with an empty sandbox."
        )

    # Handle optional parameters
    if node_packages:
        env_vars.update(_add_node_packages_env(node_packages))

    if initial_command:
        env_vars.update(_add_initial_command_env(initial_command))

    # Add environment variables and final arguments
    _add_env_vars_to_command(docker_command, env_vars)
    docker_command.extend([image_name, start_environment])

    print("\nStarting Docker container...")
    print(f"Command: {' '.join(docker_command)}\n")
    return docker_command


def _add_local_directory_mount(
    docker_command: list[str], local_dir: str
) -> dict[str, str]:
    """Add local directory mount to Docker command and return env vars."""
    abs_local_dir = _validate_local_directory(local_dir)
    docker_command.extend(["-v", f"{abs_local_dir}:/tmp/source_project:ro"])
    print(f"Configured to copy local directory: {abs_local_dir}")
    return {"SOURCE_HOST_PATH": "/tmp/source_project"}


def _add_github_repo_env(github_repo: str) -> dict[str, str]:
    """Add GitHub repository environment variable."""
    print(f"Configured to clone GitHub repository: {github_repo}")
    return {"GITHUB_REPO_URL": github_repo}


def _add_node_packages_env(node_packages: str) -> dict[str, str]:
    """Add Node.js packages environment variable."""
    print(f"Configured to install global Node packages: {node_packages}")
    return {"NODE_GLOBAL_PACKAGES": node_packages}


def _add_initial_command_env(initial_command: str) -> dict[str, str]:
    """Add initial command environment variable."""
    print(f"Configured to run initial command: '{initial_command}'")
    return {"INITIAL_COMMAND": initial_command}


def _add_env_vars_to_command(
    docker_command: list[str], env_vars: dict[str, str]
) -> None:
    """Add environment variables to Docker command."""
    for key, value in env_vars.items():
        docker_command.extend(["-e", f"{key}={value}"])


def build_docker_image(image_name: str, dockerfile_path: Path) -> None:
    """
    Builds the Docker image if it doesn't already exist.

    Args:
        image_name: The name of the Docker container image.
        dockerfile_path: The path to the Dockerfile directory.
    """
    print(f"Checking for Docker image: {image_name}")

    try:
        subprocess.run(
            ["docker", "image", "inspect", image_name],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        print(f"Image '{image_name}' already exists.")

    except FileNotFoundError:
        print(DOCKER_NOT_FOUND_ERROR)
        sys.exit(1)

    except subprocess.CalledProcessError:
        print(f"Image '{image_name}' not found. Building...")

        try:
            build_command = [
                "docker",
                "build",
                "-t",
                image_name,
                str(dockerfile_path),
            ]
            subprocess.run(build_command, check=True)
            print(f"Image '{image_name}' built successfully.")

        except subprocess.CalledProcessError as e:
            _handle_docker_error(e, "building Docker image")

        except FileNotFoundError:
            print(DOCKER_NOT_FOUND_ERROR)
            sys.exit(1)


def run_docker_container(
    image_name: str,
    local_dir: str | None = None,
    github_repo: str | None = None,
    node_packages: str | None = None,
    initial_command: str | None = None,
    start_environment: str = "bash",
) -> None:
    """Runs the Docker container with specified configurations."""
    docker_command = _build_full_docker_command(
        image_name,
        start_environment,
        local_dir,
        github_repo,
        node_packages,
        initial_command,
    )

    try:
        subprocess.run(docker_command, check=False)
    except KeyboardInterrupt:
        print("\nContainer stopped by user (Ctrl+C).")
    except FileNotFoundError:
        print(DOCKER_NOT_FOUND_ERROR)
        sys.exit(1)
    except Exception as e:
        print(f"An error occurred while running the container: {e}")
        sys.exit(1)


def _get_start_environment(command: str) -> str:
    return StartEnvironment[command.upper()].value


def create_parser() -> argparse.Namespace:
    """Create an Argparse parser for the command line arguments"""
    parser = argparse.ArgumentParser(
        description="Build and run a development sandbox container.",
        formatter_class=argparse.RawTextHelpFormatter,
    )

    parser.add_argument(
        "--dockerfile-dir",
        type=str,
        default=".",
        help="Directory containing the Dockerfile (default: current directory)",
    )

    group = parser.add_mutually_exclusive_group(required=False)
    group.add_argument(
        "--local-dir",
        type=str,
        help=(
            "Path to a local directory on the host to copy into the sandbox.\n"
            "Changes inside the container will NOT affect the original host "
            "directory."
        ),
    )
    group.add_argument(
        "--github-repo",
        type=str,
        help=(
            "URL of a GitHub repository to clone into the sandbox.\n"
            "Example: https://github.com/nodejs/node.git"
        ),
    )

    parser.add_argument(
        "--node-packages",
        type=str,
        help=(
            "Comma-separated list of Node.js packages to install globally.\n"
            "Example: nodemon,eslint,webpack"
        ),
    )
    parser.add_argument(
        "--initial-command",
        type=str,
        help=(
            "A command to run automatically after setup (e.g., 'npm install').\n"
            "This command runs in the container's working directory "
            "(/home/developer)."
        ),
    )
    parser.add_argument(
        "--command",
        type=_get_start_environment,
        default="bash",
        choices=["bash", "vscode"],
        help=(
            "The main command to run in the container after all setup.\n"
            "Defaults to 'bash'."
        ),
    )

    return parser.parse_args()


def main() -> None:
    args = create_parser()

    dockerfile_dir = Path(args.dockerfile_dir).resolve()
    if not dockerfile_dir.exists():
        print(f"Error: Dockerfile directory does not exist: {dockerfile_dir}")
        sys.exit(1)

    build_docker_image(DOCKER_IMAGE_NAME, dockerfile_dir)

    run_docker_container(
        DOCKER_IMAGE_NAME,
        local_dir=args.local_dir,
        github_repo=args.github_repo,
        node_packages=args.node_packages,
        initial_command=args.initial_command,
        start_environment=args.command,
    )


if __name__ == "__main__":
    main()
