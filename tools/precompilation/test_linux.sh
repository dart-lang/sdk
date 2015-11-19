#!/bin/bash -ex

# Usage:
#   cd sdk
#   ./tools/precompilation/test_linux.sh <dart-script-file>

./tools/build.py -mdebug -ax64 runtime

./out/DebugX64/dart_no_snapshot --gen-precompiled-snapshot "$1"

gcc -m64 -shared -Wl,-soname,libprecompiled.so -o libprecompiled.so precompiled.S

LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$PWD" gdb -ex run --args ./out/DebugX64/dart --run-precompiled-snapshot --observe --profile-vm not_used.dart
