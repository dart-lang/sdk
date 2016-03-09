#!/usr/bin/env bash

set -ex

# Usage:
#   cd sdk
#   ./tools/precompilation/test_linux.sh <dart-script-file>

./tools/build.py -mdebug -asimarm runtime

./out/DebugSIMARM/dart_bootstrap --gen-precompiled-snapshot --package-root=out/DebugX64/packages/ "$1"

gcc -nostartfiles -m32 -shared -Wl,-soname,libprecompiled.so -o libprecompiled.so precompiled.S

gdb -ex run --args ./out/DebugSIMARM/dart_precompiled_runtime --run-precompiled-snapshot=$PWD not_used.dart
