#!/bin/bash
set -e
# switch to the root directory of dev_compiler
cd $( dirname "${BASH_SOURCE[0]}" )/..

echo "*** Patching SDK"
dart -c tool/patch_sdk.dart tool/input_sdk tool/generated_sdk

echo "*** Compiling SDK to JavaScript"

# TODO(jmesserly): break out dart:html & friends.
#
# Right now we can't summarize our SDK, so we can't treat it as a normal
# explicit input (instead we're implicitly compiling against the user's SDK).
#
# Another possible approach is to hard code the dart:* library->module mapping
# into the compiler itself, so it can emit the correct import.
#
dart -c tool/build_sdk.dart \
    --dart-sdk tool/generated_sdk \
    -o lib/runtime/dart_sdk.js \
    "$@" > tool/sdk_expected_errors.txt
