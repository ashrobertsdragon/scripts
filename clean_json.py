import argparse
import logging
import json
import sys
from pathlib import Path
from typing import Any

logger = logging.getLogger(__name__)


def setup_logger(args: argparse.Namespace) -> None:
    """Sets up the logger for the program."""
    formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")

    log_level = {
        0: logging.ERROR,
        1: logging.INFO,
        2: logging.DEBUG,
    }.get(args.verbosity, logging.ERROR)

    logger.setLevel(log_level)

    if not args.quiet:
        stdout_handler = logging.StreamHandler(sys.stdout)
        stdout_handler.setLevel(log_level)
        stdout_handler.setFormatter(formatter)
        logger.addHandler(stdout_handler)

    if args.log_file:
        file_handler = logging.FileHandler(args.log_file)
        file_handler.setLevel(log_level)
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)
        logger.debug(f"File logging enabled: {args.log_file}")

    logger.debug(
        f"Logger initialized with level {logging.getLevelName(log_level)}"
    )


def create_parser() -> argparse.ArgumentParser:
    """Creates the argument parser."""
    parser = argparse.ArgumentParser(
        description="JSON sorter and dot-expander"
    )

    json_source = parser.add_mutually_exclusive_group(required=True)
    json_source.add_argument(
        "-f", "--file", type=Path, help="Path to JSON file"
    )
    json_source.add_argument(
        "-s",
        "--string",
        type=str,
        help="JSON string with escaped quotes",
        dest="data",
    )
    json_source.add_argument(
        "-i",
        "--stdin",
        action="store_true",
        help="JSON object directly from stdin",
    )

    verbosity = parser.add_mutually_exclusive_group()
    verbosity.add_argument(
        "-v",
        "--verbose",
        action="store_const",
        const=1,
        dest="verbosity",
        help="Verbose mode",
    )
    verbosity.add_argument(
        "-vv",
        "--very-verbose",
        action="store_const",
        const=2,
        dest="verbosity",
        help="Very verbose mode",
    )
    parser.set_defaults(verbosity=0)

    parser.add_argument(
        "-q", "--quiet", action="store_true", help="Suppress console output"
    )
    parser.add_argument("-l", "--log-file", type=str, help="Path to log file")

    return parser


class JSONSorter:
    def __init__(self) -> None:
        self._exit_code = 0
        self._exception_message: str | None = None

        self.output: str | None = None

    def _expand_dot_notation(self, data: dict[str, Any]) -> dict[str, Any]:
        """Converts dot notation keys in a flat dictionary into nested dictionaries."""
        result: dict[str, Any] = {}
        for key, value in data.items():
            parts: list[str] = key.split(".")
            if len(parts) == 1:
                result[key] = value
                continue
            logger.debug(f"Expanding dot notation for key: {key}")
            current = result
            for part in parts[:-1]:
                try:
                    current = current.setdefault(part, {})
                except TypeError:
                    self._exception_message = (
                        f"Could not expand key: {key}. Conflict at {part}"
                    )
                    self._exit_code = 1
                    raise
            current[parts[-1]] = value
        logger.debug(f"Expanded dictionary: {result}")
        return result

    def _sort_values(self, obj: Any) -> Any:
        """Recursively sorts dictionaries by key, leaving lists in original order."""
        if isinstance(obj, dict):
            logger.debug(f"Sorting dictionary keys: {list(obj.keys())}")
            expanded = self._expand_dot_notation(obj)
            return {
                k: self._sort_values(expanded)
                for k, v in sorted(obj.items())
            }
        elif isinstance(obj, list):
            return [self._sort_values(item) for item in obj]
        return obj

    def _process_and_pretty_print_json(self, json_string: str) -> str:
        """Sorts JSON by key and expands dot notation."""
        logger.info("Processing JSON input...")
        try:
            data = json.loads(json_string)
            logger.debug("JSON parsed successfully")
            sorted_data = self._sort_values(data)
            pretty_json = json.dumps(
                sorted_data, indent=2, separators=(",", ": ")
            )
            logger.debug("JSON processed successfully")
            return pretty_json
        except json.JSONDecodeError as e:
            logger.exception(f"Error decoding JSON: {e}")
            self._exit_code = 1
            raise

    def _read_file(self, filepath: Path) -> str:
        """Reads file and returns str or exits on error."""
        logger.info(f"Reading file: {filepath}")
        try:
            content = filepath.read_text(encoding="utf-8", errors="strict")
            logger.debug(f"File read successfully, {len(content)} bytes")
            return content
        except (OSError, UnicodeError) as e:
            self._exception_message = f"Error reading file: {e}"
            self._exit_code = 1
            raise

    def _write_file(self, filepath: Path, data: str) -> None:
        """Writes data to file."""
        logger.info(f"Writing output to file: {filepath}")
        try:
            filepath.write_text(data, encoding="utf-8")
            logger.debug(f"File written successfully ({len(data)} bytes)")
        except OSError as e:
            self._exception_message = f"Could not write file: {e}"
            self._exit_code = 1
            raise

    def sort(self, args: argparse.Namespace) -> None:
        """Main execution routine."""
        logger.debug(f"Sorting JSON with arguments: {args}")

        json_string = self._read_file(args.file) if args.file else args.data

        pretty_json = self._process_and_pretty_print_json(json_string)

        if args.file:
            self._write_file(args.file, pretty_json)

        if (not args.quiet and args.verbosity > 0) or args.data:
            self.output = "Successfully processed JSON:\n" + pretty_json

    def run(self, args: argparse.Namespace) -> int:
        try:
            self.sort(args)
        except (
            OSError,
            UnicodeError,
            TypeError,
            json.JSONDecodeError,
        ):
            logger.exception(self._exception_message)
        except Exception as e:
            logger.exception(f"An unexpected error occurred: {e}")
        finally:
            logger.debug(f"Exiting program with code {self._exit_code}")
            return self._exit_code


def main() -> None:
    """Entry point for the program."""
    try:
        args = create_parser().parse_args()
        if args.stdin:
            if not sys.stdin:
                print("Error: --stdin flag used but no stdin input found")
                sys.exit(2)
            args.data = sys.stdin
        setup_logger(args)
        logger.debug("Starting JSONSorter() execution")

        if args.quiet and args.data:
            print(
                "Error: --quiet cannot be used with --string or --raw input."
            )
            sys.exit(2)

        sorter = JSONSorter()
        exit_code = sorter.run(args)
        if sorter.output:
            print(sorter.output)
        sys.exit(exit_code)

    except argparse.ArgumentTypeError as e:
        print(str(e))
        sys.exit(1)


if __name__ == "__main__":
    main()
