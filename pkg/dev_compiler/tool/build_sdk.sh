#!/bin/bash
set -e
# switch to the root directory of dev_compiler
cd $( dirname "${BASH_SOURCE[0]}" )/..

echo "*** Patching SDK"
dart -c tool/patch_sdk.dart tool/input_sdk tool/generated_sdk

echo "*** Compiling SDK to JavaScript"

dart -c bin/devc.dart --no-source-maps --arrow-fn-bind-this --sdk-check \
    --force-compile -l warning --dart-sdk tool/generated_sdk -o lib/runtime/ \
    "$@" \
    dart:js dart:mirrors \
    > tool/sdk_expected_errors.txt || true
