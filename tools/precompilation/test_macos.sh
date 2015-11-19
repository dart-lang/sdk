#!/bin/bash -ex

# Usage:
#   cd sdk
#   ./tools/precompilation/test_macos.sh <dart-script-file>

./tools/build.py -mdebug -ax64 runtime

./xcodebuild/DebugX64/dart_no_snapshot --gen-precompiled-snapshot "$1"

clang -m64 -dynamiclib -o libprecompiled.dylib precompiled.S

LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$PWD" lldb -- ./xcodebuild/DebugX64/dart --run-precompiled-snapshot --observe not_used.dart
