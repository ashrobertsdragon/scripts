#!/bin/bash

# SYNOPSIS
#     Runs a series of quality checks on the codebase.
#
# DESCRIPTION
#     This script ensures the codebase meets quality standards by running a series of checks. It initializes a quality checking tool (qlty), configures it, and then runs a sequence of commands including linting, formatting, and type checking.
#
# EXAMPLE
#     ./Rub-ADubDub.sh

print_help() {
    echo "Usage: ./Rub-ADubDub.sh"
    echo ""
    echo "Runs a series of quality checks on the codebase."
    echo ""
    echo "This script ensures the codebase meets quality standards by running a series of checks. It initializes a quality checking tool (qlty), configures it, and then runs a sequence of commands including linting, formatting, and type checking."
    echo ""
    echo "Options:"
    echo "  -h, --help   Show this help message and exit"
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    print_help
    exit 0
fi

assert_success() {
    local code=$?
    local context=$1

    if [ $code -ne 0 ]; then
        echo "$context failed with exit code $code"
        exit $code
    fi
}

if [ ! -d ".qlty" ]; then
    echo "Initializing qlty..."
    qlty init --no
    assert_success "qlty init"

    sed -i 's/^]/  "**\/tests\/**",\n]/g' .qlty/qlty.toml
fi

if ! grep -q '**\/tests\/**' .qlty/qlty.toml; then
    echo "Tests path missing from qlty.toml"
    exit 1
}

if grep -q 'ruff' .qlty/qlty.toml; then
    qlty plugins disable ruff
    assert_success "Disabling ruff plugin"
}

if grep -q 'markdownlint' .qlty/qlty.toml; then
    qlty plugins disable markdownlint
    assert_success "Disabling markdownlint plugin"
}

commands=(
    "uvx ruff check --fix ."
    "uvx ruff format"
    "qlty check --all --no-formatters --fix --fail-level=low"
    "uvx mypy ."
    "uvx ruff check --fix ."
    "uvx ruff format"
)

for command in "${commands[@]}"; do
    echo -e "\nRunning: $command"
    eval "$command"
    assert_success "$command"
done

echo -e "\nAll quality checks completed successfully!"
