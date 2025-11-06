# /// script
# dependencies = ["requests"]
# ///

import argparse
import atexit
import contextlib
import ftplib
import logging
import json
import re
import tempfile
import tarfile
from collections.abc import Generator, Iterator
from datetime import datetime
from pathlib import Path
from urllib.parse import urlparse

import requests


TZ_DATA_URL = "ftp://ftp.iana.org/tz/tzdata-latest.tar.gz"
DEFAULT_OUTPUT_FILE = Path.cwd() / "tz_data.json"

logger = logging.getLogger(__name__)
to_cleanup = []


def is_valid_file(filename: Path) -> bool:
    """Check if a file is a valid timezone region file.

    Args:
        filename (Path): The path to the file to check.

    Returns:
        bool: True if the file is a valid timezone region file, False otherwise.
    """
    return filename.name.islower() and "." not in filename.name


def parse_timezones(filename: Path) -> Iterator[tuple[str, str]]:
    """Parse a timezone region file and return zone offsets.

    Args:
        filename (Path): The path to the timezone region file.

    Yields:
        Iterator[tuple[str, str]]: A tuple containing the zone name and the
        offset for that zone.
    """
    in_zone: bool = False
    zone: str = ""

    for data_line in filename.open("r", encoding="utf-8"):
        line = data_line.strip()

        if "#" in line or not line:
            continue

        if line.startswith("Zone"):
            zone = line.split()[1]
            in_zone = True

        elif in_zone:
            if not re.search(r"\b\d{4}\b", line):
                in_zone = False
                offset = line.split()[0]
                logger.debug(f"Zone: {zone}, Offset: {offset}")
                yield zone, offset


def parse_timezone_data(tz_dir: Path) -> dict[str, str]:
    """Parse timezone region files and return zone offsets.

    Args:
        tz_dir (Path): The path to the timezone region directory.

    Returns:
        dict[str, str]: A dictionary mapping zone names to their offsets.
    """
    zones = []
    for file in tz_dir.iterdir():
        if is_valid_file(file):
            logger.info(f"Parsing timezone region file: {file}")

            zones.extend(
                (zone, offset) for zone, offset in parse_timezones(file)
            )
    return dict(sorted(zones))


def write_results(results: dict[str, str], output_file: Path) -> None:
    """Write results to a JSON file."""
    with output_file.open("w") as f:
        json.dump(results, f, indent=2)

    logger.info(f"Results written to {output_file}")


def convert_verbosity(verbosity: int) -> str:
    logging_level = {0: "ERROR", 1: "INFO", 2: "DEBUG"}
    return logging_level[verbosity]


def setup_logging(args: argparse.Namespace) -> None:
    """Set up logging for the script."""
    logging.basicConfig(
        format="%(asctime)s - %(levelname)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        handlers=[logging.StreamHandler(), logging.FileHandler(args.log_file)]
        if args.log_file
        else [logging.StreamHandler()],
    )
    logger.setLevel(getattr(logging, convert_verbosity(args.verbosity)))

    if args.quiet:
        logger.setLevel(logging.CRITICAL)
        logger.disabled = True


# download and extract timezone data
def filter_file(
    member: tarfile.TarInfo, destination: Path
) -> tarfile.TarInfo | None:
    """
    Filter out files that are not timezone region files and apply data filter.

    Args:
        member (tarfile.TarInfo): The member to filter.
        destination (Path): The destination path.

    Returns:
        tarfile.TarInfo | None: The filtered member or None if the member is not a valid file.
    """
    return (
        tarfile.data_filter(member, destination)
        if is_valid_file(Path(member.name))
        else None
    )


class LoggedTarFile(tarfile.TarFile):
    """Override debug method to logger for tarfile.TarFile."""

    def _dbg(self, level, msg) -> None:
        if level <= self.debug:
            message = f"tarfile: {msg}" if level == 1 else msg
            logger.debug(message)


def extract_tarfile(tar_file: Path, log_level: int) -> Path:
    """Extract a tar.gz file to a temporary directory."""
    temp_dir = Path(tempfile.mkdtemp(prefix="tzdata_"))
    debug_level: int = 3 if log_level > 0 else 0

    tar_func = LoggedTarFile if debug_level > 0 else tarfile.TarFile
    try:
        with tar_func.open(tar_file, "r:gz", debug=debug_level) as tar:
            tar.extractall(path=temp_dir, filter=filter_file)
        return temp_dir

    except tarfile.TarError as e:
        logger.error("Failed to extract timezone data", exc_info=True)
        raise RuntimeError(f"Failed to extract timezone data: {e}")
    except Exception:
        logger.error("An error occurred during extraction", exc_info=True)
        raise

    finally:
        if not tar.fileobj.closed:
            logger.debug("Tar fileobj still open, closing")
            tar.fileobj.close()
        if not tar.closed:
            logger.debug("Tar file still open, closing")
            tar.close()


def download_http(
    database_url: str,
) -> Path:
    """Download a file from an HTTP server to a temporary file."""
    logger.info(f"Downloading timezone data from {database_url}")
    download_start = datetime.now()

    try:
        response = requests.get(database_url, stream=True)
        response.raise_for_status()

        download_file = Path(
            tempfile.NamedTemporaryFile(suffix=".tar.gz", delete=False).name
        )
        with download_file.open("wb") as opened:
            for chunk in response.iter_content(chunk_size=8192):
                opened.write(chunk)

        download_time = datetime.now() - download_start
        logger.debug(
            "Downloaded timezone data in {} seconds".format(
                download_time.total_seconds()
            )
        )
        return download_file

    except requests.exceptions.RequestException as e:
        logger.error("Failed to download http data", exc_info=True)
        raise RuntimeError(f"Failed to download http data: {e}")


def download_ftp(database_url: str, log_level: int) -> Path:
    """Download a file from an FTP server to a temporary file."""
    parsed_url = urlparse(database_url)
    host = parsed_url.hostname
    file = parsed_url.path

    logger.info(f"Downloading timezone data from {database_url}")
    download_start = datetime.now()
    try:
        download_file = Path(
            tempfile.NamedTemporaryFile(suffix=".tar.gz", delete=False).name
        )
        with ftplib.FTP(host) as ftp:
            ftp.set_debuglevel(level=log_level)
            ftp.login()
            with download_file.open("wb") as opened:
                ftp.retrbinary(f"RETR {file}", opened.write)
            if not opened.closed:
                logger.debug("Download file still open, closing")
                opened.close()
            ftp.quit()
        download_time = datetime.now() - download_start
        logger.debug(
            "Downloaded timezone data in {} seconds".format(
                download_time.total_seconds()
            )
        )
        return download_file

    except ftplib.Error as e:
        logger.error("Failed to download FTP data", exc_info=True)
        raise RuntimeError(f"Failed to download FTP data: {e}")


def _cleanup() -> None:
    """Cleanup temporary files and directories."""
    file: Path = to_cleanup[0]
    directory: Path = to_cleanup[1]
    if file and file.exists():
        try:
            file.unlink(missing_ok=True)
            logger.debug(f"Removed {file}")
        except PermissionError as e:
            logger.warning(f"Failed to remove {file}: {e}")
        except FileNotFoundError:
            pass

    if directory and directory.exists():
        logger.debug(f"Removing {directory}")
        try:
            for item in directory.iterdir():
                item.unlink(missing_ok=True)
            directory.rmdir()
            logger.debug(f"Removed {directory}")
        except PermissionError as e:
            logger.warning(f"Failed to remove {directory}: {e}")
        except FileNotFoundError:
            pass


@contextlib.contextmanager
def get_timezone_data(
    database_url: str, log_level: int
) -> Generator[Path, None, None]:
    """Download timezone data and yield the path to the extracted directory."""

    scheme: str = urlparse(database_url).scheme
    logger.debug(f"URL is {database_url}, using {scheme} downloader")

    download_file: Path = (
        download_ftp(database_url, log_level)
        if scheme == "ftp"
        else download_http(database_url)
    )
    to_cleanup.append(download_file)
    temp_dir: Path = extract_tarfile(download_file, log_level)
    yield temp_dir
    to_cleanup.append(temp_dir)


# argument parsing
def check_tz_dir(tz_dir: str) -> Path:
    """Check that the timezone directory exists and is a directory."""
    tz_dir = Path(tz_dir)
    if not tz_dir.exists():
        raise argparse.ArgumentTypeError(f"Directory {tz_dir} does not exist")
    return tz_dir


def check_tz_url(tz_url: str) -> str:
    """Check that the timezone URL starts with http:// or ftp://."""
    if urlparse(tz_url).scheme not in ["http", "ftp"]:
        raise argparse.ArgumentTypeError(
            f"URL {tz_url} must start with http:// or ftp://"
        )
    return tz_url


class StoreLogFile(argparse.Action):
    def __call__(self, parser, namespace, values, option_string=None) -> None:
        if not getattr(namespace, "verbosity", 0):
            logger.error(
                "Verbosity must be set to at least 'INFO' to log to a file."
            )
            parser.error(
                f"{option_string} requires a verbosity level to be set (e.g., --verbose, --very-verbose, -v, -vv)."
            )
        setattr(namespace, self.dest, values)


def create_parser() -> argparse.Namespace:
    """Create an argument parser for the script."""
    parser = argparse.ArgumentParser(
        prog="Parse timezone data",
        description="Parse timezone data from the IANA database and write it to a JSON file.",
    )
    parser.add_argument(
        "-o",
        "--output",
        help="Path to the output JSON file",
        type=Path,
        metavar="PATH",
        default=DEFAULT_OUTPUT_FILE,
        dest="output_file",
    )
    location = parser.add_argument_group("Timezone data location")
    tz_location = location.add_mutually_exclusive_group()
    tz_location.add_argument(
        "-d",
        "--dir",
        help="Path to the timezone directory",
        type=check_tz_dir,
        metavar="PATH",
        dest="tz_dir",
    )
    tz_location.add_argument(
        "-u",
        "--url",
        help="URL to the timezone data",
        type=check_tz_url,
        metavar="URL",
        dest="tz_url",
        default=TZ_DATA_URL,
    )

    verbosity = parser.add_argument_group(title="Logging options")

    verbosity_args = verbosity.add_mutually_exclusive_group()
    verbosity_args.add_argument(
        "-v",
        action="count",
        help="Enable logging verbosity with -v and -vv",
        default=0,
        dest="verbosity",
    )
    verbosity_args.add_argument(
        "-q",
        "--quiet",
        action="store_true",
        help="Disable logging",
        dest="quiet",
    )

    verbosity_args.add_argument(
        "--verbose",
        action="store_const",
        const="1",
        help="Enable verbose logging",
        dest="verbosity",
    )
    verbosity_args.add_argument(
        "--very-verbose",
        action="store_const",
        const="2",
        help="Enable very verbose logging",
        dest="verbosity",
    )

    verbosity.add_argument(
        "-l",
        "--log-file",
        help="Path to the log file (verbosity level must be set)",
        action=StoreLogFile,
        type=Path,
        metavar="PATH",
        dest="log_file",
    )
    return parser.parse_args()


def main() -> None:
    """Main entry point for the script."""
    atexit.register(_cleanup)
    args = create_parser()

    setup_logging(args)

    with (
        get_timezone_data(args.tz_url, args.verbosity)
        if not args.tz_dir
        else contextlib.nullcontext(args.tz_dir)
    ) as tz_dir:
        logger.debug(
            f"Timezone data downloaded from {args.tz_url}"
            if not args.tz_dir
            else f"Using timezone directory {tz_dir}"
        )
        timezones = parse_timezone_data(tz_dir)
        write_results(timezones, args.output_file)


if __name__ == "__main__":
    main()
