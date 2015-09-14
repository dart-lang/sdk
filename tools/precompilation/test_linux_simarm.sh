#!/bin/bash -ex

# Usage:
#   cd sdk
#   ./tools/precompilation/test_linux.sh

./tools/build.py -mdebug -asimarm runtime

./out/DebugSIMARM/dart_no_snapshot --gen-precompiled-snapshot ~/hello.dart

gcc -m32 -shared -Wl,-soname,libprecompiled.so -o libprecompiled.so precompiled.S

LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$PWD" gdb -ex run --args ./out/DebugSIMARM/dart --run-precompiled-snapshot not_used.dart
