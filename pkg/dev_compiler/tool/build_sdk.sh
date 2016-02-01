#!/bin/bash
set -e
# switch to the root directory of dev_compiler
cd $( dirname "${BASH_SOURCE[0]}" )/..

echo "*** Patching SDK"
dart -c tool/patch_sdk.dart tool/input_sdk tool/generated_sdk

echo "*** Compiling SDK to JavaScript"

# TODO(ochafik): Re-enable named params destructuring when Atom supports it
# (see https://github.com/dart-lang/dev_compiler/issues/396)
dart -c bin/dartdevc.dart --force-compile --no-source-maps --sdk-check \
    -l warning --dart-sdk tool/generated_sdk -o lib/runtime/ \
    --no-destructure-named-params \
    "$@" \
    dart:_runtime \
    dart:_debugger \
    dart:js dart:mirrors dart:html \
    > tool/sdk_expected_errors.txt || true
