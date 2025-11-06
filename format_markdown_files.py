from pathlib import Path
import subprocess


def format_markdown_files(root_dir: Path = Path.cwd()) -> None:
    config_path = "C:/Users/ashro/.claude/hooks/.markdown-format.json"

    for md_file in root_dir.rglob("*.md"):
        subprocess.run([
            "markdown-format.cmd",
            "-use-config",
            config_path,
            "--replace",
            "--file",
            str(md_file),
        ])
        print(f"Formatted: {md_file}")


if __name__ == "__main__":
    format_markdown_files()
