#!/usr/bin/env bash

set -ex

# Usage:
#   cd sdk
#   ./tools/precompilation/test_linux.sh <dart-script-file>

./tools/build.py -mdebug -ax64 runtime

./out/DebugX64/dart_bootstrap --gen-precompiled-snapshot --package-root=out/DebugX64/packages/ "$1"

gcc -nostartfiles -m64 -shared -Wl,-soname,libprecompiled.so -o libprecompiled.so precompiled.S

gdb -ex run --args ./out/DebugX64/dart_precompiled_runtime --run-precompiled-snapshot=$PWD not_used.dart
