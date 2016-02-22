#!/bin/bash
set -e
DIR=$(dirname "${BASH_SOURCE[0]}")
$DIR/build_sdk.sh
$DIR/test.sh
$DIR/browser_test.sh
$DIR/node_test.sh
$DIR/analyze.sh
$DIR/format.sh
# TODO(vsm/ochafik): Re-enable when this is addressed:
# https://github.com/dart-lang/dev_compiler/issues/458
# $DIR/transformer_test.sh
