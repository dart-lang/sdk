#!/usr/bin/env bash

set -ex

# Usage:
#   cd sdk
#   ./tools/precompilation/test_macos.sh <dart-script-file>

./tools/build.py -mdebug -ax64 runtime

./xcodebuild/DebugX64/dart_bootstrap --gen-precompiled-snapshot --package-root=xcodebuild/DebugX64/packages/ "$1"

clang -nostartfiles -m64 -dynamiclib -o libprecompiled.dylib precompiled.S

lldb -- ./xcodebuild/DebugX64/dart_precompiled_runtime --run-precompiled-snapshot=$PWD not_used.dart
