#!/bin/bash
set -e
# switch to the root directory of dev_compiler
cd $( dirname "${BASH_SOURCE[0]}" )/..

output_dir=`mktemp -d /tmp/ddc_node_test.XXXXXX`

ddc_options=(
  --destructure-named-params
  --modules=node
  -o $output_dir
)
node_harmony_options=(
  --harmony
  --harmony_destructuring
  --harmony_default_parameters
)
function compile() {
    ./bin/dartdevc.dart "${ddc_options[@]}" $1
}
function run() {
  NODE_PATH=$output_dir \
    node "${node_harmony_options[@]}" -e \
    "require('dart/_isolate_helper').startRootIsolate(require('$1').main, []);"
}

# TODO(ochafik): Add full language tests (in separate Travis env/matrix config).

echo "*** Compiling SDK for node to $output_dir"

dart bin/dartdevc.dart --force-compile --no-source-maps --sdk-check \
    -l warning --dart-sdk tool/generated_sdk -o lib/runtime/ \
    --no-destructure-named-params \
    "${ddc_options[@]}" \
    dart:_runtime \
    dart:_debugger \
    dart:js dart:mirrors dart:html || true

echo "*** Compiling hello_dart_test"
compile test/codegen/language/hello_dart_test.dart
run hello_dart_test

echo "*** Compiling DeltaBlue"
compile test/codegen/DeltaBlue.dart
run DeltaBlue
