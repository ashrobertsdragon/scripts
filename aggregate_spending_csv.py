import csv
import sys
from collections import defaultdict
from collections.abc import Generator
from datetime import datetime


def read_csv_rows(filepath: str) -> Generator[dict[str, str], None, None]:
    """Reads a CSV file and yields each row as a dictionary.

    Args:
        filepath (str): The path to the CSV file.

    Yields:
        dict[str, str]: A dictionary representing a row from the CSV file.
    """
    with open(filepath, newline="", encoding="utf-8") as csvfile:
        yield from csv.DictReader(csvfile)


def parse_transaction_row(
    row: dict[str, str], date_format: str
) -> tuple[str, float]:
    """Parses and validates data from a single transaction row.

    Args:
        row (dict[str, str]): A dictionary representing a single CSV row.
        date_format (str): The expected format of the date string
            (e.g., '%m/%d/%Y').

    Returns:
        tuple[str, float]: A tuple containing the month-year string
            (YYYY-MM) and the amount.
    """
    date_str = row["date"]
    dt_object = datetime.strptime(date_str, date_format)
    month_year = dt_object.strftime("%Y-%m")

    amount_str = row["amount"]
    amount = float(amount_str)

    return month_year, amount


def filter_and_aggregate_transactions(
    transactions_reader: Generator[dict[str, str], None, None],
    keyword: str,
    date_format: str,
) -> dict[str, float]:
    """Filters transactions by keyword in the memo and aggregates amounts.

    Args:
        transactions_reader (Generator[dict[str, str], None, None]): A
            generator yielding CSV rows.
        keyword (str): The string to search for in the 'memo' column.
        date_format (str): The format of the date string (e.g., '%m/%d/%Y').

    Returns:
        dict[str, float]: A dictionary where keys are 'YYYY-MM' strings and
            values are the total aggregated amounts for transactions matching
            the search term.

    Raises:
        ValueError: If no transactions found.
    """
    monthly_totals: dict[str, float] = defaultdict(float)

    for row_num, row in enumerate(
        transactions_reader, start=2
    ):  # Start at 2 for header + first data row
        memo = row["memo"]
        if keyword.upper() not in memo.upper():
            continue

        month_year, amount = parse_transaction_row(row, date_format)
        monthly_totals[month_year] += amount

    if not monthly_totals:
        raise ValueError(
            f"No transactions found containing '{keyword}' in the memo."
        )

    return monthly_totals


def report_monthly_totals(monthly_data: dict[str, float], keyword: str) -> None:
    """Prints the aggregated monthly totals.

    Args:
        monthly_data (dict[str, float]): A dictionary of monthly totals.
        keyword (str): The original search term for context in the report.
    """
    print(f"\n--- Monthly Spending for '{keyword}' ---")
    for month_year in sorted(monthly_data.keys()):
        print(f"{month_year}: ${monthly_data[month_year]:,.2f}")


def analyze_and_report(
    filepath: str, keyword: str = "KING SOOPERS", date_format: str = "%m/%d/%Y"
) -> None:
    """Searches for keyword in CSV file and aggregates monthly totals.

    Args:
        filepath (str): The path to the CSV file.
        keyword (str): The string to search for in the 'memo' column.
        date_format (str): The format the date will be in
            (default is '%m/%d/%Y').
    """
    print(f"Starting analysis for '{filepath}' with search term '{keyword}'...")
    transaction_rows = read_csv_rows(filepath)

    aggregated_data = filter_and_aggregate_transactions(
        transactions_reader=transaction_rows,
        keyword=keyword,
        date_format=date_format,
    )
    report_monthly_totals(aggregated_data, keyword)


def print_help():
    """Prints the help message for the script."""
    print("Usage: python agregate_spending_csv.py <filepath> [keyword] [date_format]")
    print("\nAnalyzes spending from a CSV file.")
    print("\nArguments:")
    print("  filepath:    The path to the CSV file.")
    print("  keyword:     The string to search for in the 'memo' column (default: 'KING SOOPERS').")
    print("  date_format: The format of the date string (default: '%m/%d/%Y').")


def main() -> None:
    """Collect arguments and run script.

    Returns: None.

    Raises:
        RuntimeError: If incorrect number of arguments
    """
    if "-h" in sys.argv:
        print_help()
        sys.exit(0)

    if 1 > len(sys.argv) > 4:
        raise RuntimeError("Incorrect number of arguments")

    args = sys.argv[1:]
    analyze_and_report(*args)


if __name__ == "__main__":
    main()
