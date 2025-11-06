import json
import sys
from collections.abc import Generator


def read_file(filename: str) -> Generator[str, None, None]:
    with open(filename, "r") as f:
        for line in f:
            yield line


def write_json(filename: str, data: dict[str, str]):
    with open(filename, "w") as f:
        json.dump(data, f, indent=2)


def get_key_value(line: str):
    key, value = line.split(":", maxsplit=1)
    return key.strip(), value.strip()


def form_dict(gen: Generator[str]):
    zones = {}
    tz = {}
    for line in gen:
        if line.strip():
            key, value = get_key_value(line)
            tz[key] = value
            continue

        if not tz:
            continue

        zones[tz["Id"]] = tz
        tz = {}
    return zones


def print_help():
    """Prints the help message for the script."""
    print("Usage: python convert_PS_table.py <zone_file> <output_file>")
    print("\nConverts a PowerShell table to a JSON file.")
    print("\nArguments:")
    print("  zone_file:   The path to the input file containing the PowerShell table.")
    print("  output_file: The path to the output JSON file.")


if __name__ == "__main__":
    if "-h" in sys.argv:
        print_help()
        sys.exit(0)

    if len(sys.argv) != 3:
        print("Usage: python script.py <zone_file> <output_file>")
        sys.exit(1)
    zone_file = sys.argv[1]
    output_file = sys.argv[2]
    zones = form_dict(read_file(zone_file))
    write_json(output_file, zones)
