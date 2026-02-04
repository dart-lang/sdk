#!/usr/bin/env bash
set -e
set -x

# Usage: ./validate_wasm_test.sh <dart_file>
if [ -z "$1" ]; then
  echo "Usage: $0 <dart_file>"
  exit 1
fi

INPUT_FILE="$1"
# Get absolute path of input file
if [[ "$INPUT_FILE" != /* ]]; then
  INPUT_FILE="$(pwd)/$INPUT_FILE"
fi

BASENAME=$(basename "$INPUT_FILE" .dart)
OUTPUT_WASM="${INPUT_FILE%.dart}.wasm"

# Resolve script directory to handle running from anywhere
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Assuming script is in pkg/dart2wasm/tool
DART2WASM_TOOL_DIR="$SCRIPT_DIR"

# Compile
"$DART2WASM_TOOL_DIR/compile_benchmark" \
  --src \
  -O0 \
  --extra-compiler-option=--enable-experimental-wasm-interop \
  "$INPUT_FILE" \
  "$OUTPUT_WASM"

# Run
"$DART2WASM_TOOL_DIR/run_benchmark" \
  --d8 \
  "$OUTPUT_WASM"
