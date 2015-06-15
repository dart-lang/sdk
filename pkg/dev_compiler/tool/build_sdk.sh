#!/bin/bash
set -e
# switch to the root directory of dev_compiler
cd $( dirname "${BASH_SOURCE[0]}" )/..

echo "*** Patching SDK"
rm -r tool/generated_sdk || true
dart -c tool/patch_sdk.dart tool/input_sdk tool/generated_sdk

echo "*** Compiling SDK to JavaScript"
if [[ -d lib/runtime/dart ]] ; then
  rm -r lib/runtime/dart
fi

# TODO(jmesserly): this builds dart:js, which pulls in dart:core and many others
# transitively. Ideally we could pass them explicitly, though:
# https://github.com/dart-lang/dev_compiler/issues/219
dart -c bin/devc.dart --no-source-maps --sdk-check --force-compile -l warning \
    --dart-sdk tool/generated_sdk -o lib/runtime/ dart:mirrors \
    > tool/generated_sdk/sdk_errors.txt || true

if [[ ! -f lib/runtime/dart/core.js ]] ; then
    echo 'core.js not found, assuming build failed.'
    echo './tool/build_sdk.sh can be run to reproduce this.'
    exit 1
fi

DIFF_ARGS="-u tool/sdk_expected_errors.txt tool/generated_sdk/sdk_errors.txt"

if ! (diff $DIFF_ARGS > /dev/null) ; then
    diff $DIFF_ARGS |\
        sed -e "s/^\(+.*\)/[32m\1[0m/" |\
        sed -e "s/^\(-.*\)/[31m\1[0m/"
    echo
    echo 'SDK errors have changed.  To update expectations, run:'
    echo '$ cp tool/generated_sdk/sdk_errors.txt tool/sdk_expected_errors.txt'
    exit 1
fi
