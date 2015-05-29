#!/bin/bash
set -e
# switch to the root directory of dev_compiler
cd $( dirname "${BASH_SOURCE[0]}" )/..

echo "*** Patching SDK"
rm -r test/generated_sdk || true
dart -c tool/patch_sdk.dart tool/input_sdk test/generated_sdk

echo "*** Compiling SDK to JavaScript"
if [[ -d lib/runtime/dart ]] ; then
  rm -r lib/runtime/dart
fi

# TODO(jmesserly): for now we're suppressing errors in SDK compilation
dart -c bin/devc.dart --no-source-maps --sdk-check --force-compile -l warning \
    --dart-sdk test/generated_sdk -o lib/runtime/ dart:core \
    > test/generated_sdk/sdk_errors.txt || true

if [[ ! -f lib/runtime/dart/core.js ]] ; then
    echo 'core.js not found, assuming build failed.'
    echo './tool/build_sdk.sh can be run to reproduce this.'
    exit 1
fi

DIFF_ARGS="-u tool/sdk_expected_errors.txt test/generated_sdk/sdk_errors.txt"

if ! (diff $DIFF_ARGS > /dev/null) ; then
    diff $DIFF_ARGS |\
        sed -e "s/^\(+.*\)/[32m\1[0m/" |\
        sed -e "s/^\(-.*\)/[31m\1[0m/"
    echo
    echo 'SDK errors have changed.  To update expectations, run:'
    echo '$ cp test/generated_sdk/sdk_errors.txt tool/sdk_expected_errors.txt'
    exit 1
fi
