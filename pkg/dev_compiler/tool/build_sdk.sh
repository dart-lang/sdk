#!/bin/bash
set -e
# switch to the root directory of dev_compiler
cd $( dirname "${BASH_SOURCE[0]}" )/..

echo "*** Patching SDK"
dart -c tool/patch_sdk.dart tool/input_sdk gen/patched_sdk

echo "*** Compiling SDK to JavaScript"

# TODO(jmesserly): break out dart:html & friends.
dart -c bin/dartdevc.dart \
    --dart-sdk gen/patched_sdk \
    -o lib/runtime/dart_sdk.js \
    --unsafe-force-compile --no-source-map --no-emit-metadata \
    dart:_runtime \
    dart:_debugger \
    dart:_foreign_helper \
    dart:_interceptors \
    dart:_internal \
    dart:_isolate_helper \
    dart:_js_embedded_names \
    dart:_js_helper \
    dart:_js_mirrors \
    dart:_js_primitives \
    dart:_metadata \
    dart:_native_typed_data \
    dart:async \
    dart:collection \
    dart:convert \
    dart:core \
    dart:isolate \
    dart:js \
    dart:math \
    dart:mirrors \
    dart:typed_data \
    dart:indexed_db \
    dart:html \
    dart:html_common \
    dart:svg \
    dart:web_audio \
    dart:web_gl \
    dart:web_sql \
    "$@" > tool/sdk_expected_errors.txt
