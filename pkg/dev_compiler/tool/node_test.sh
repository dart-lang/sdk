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

echo "Compiling SDK for node to $output_dir"
./tool/build_sdk.sh "${ddc_options[@]}"

echo "Now compiling hello_dart_test"
compile test/codegen/language/hello_dart_test.dart
run hello_dart_test

echo "Now compiling DeltaBlue"
compile test/codegen/DeltaBlue.dart
run DeltaBlue
