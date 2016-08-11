#!/bin/bash
set -e # bail on error

cd $( dirname "${BASH_SOURCE[0]}" )/..

mkdir -p gen/codegen_output/pkg/

SDK=--dart-sdk-summary=lib/runtime/dart_sdk.sum

./bin/dartdevc.dart $SDK -o gen/codegen_output/pkg/expect.js \
    --url-mapping=package:expect/expect.dart,test/codegen/expect.dart \
    package:expect/expect.dart

./bin/dartdevc.dart $SDK  -o gen/codegen_output/pkg/async_helper.js \
    --url-mapping=package:async_helper/async_helper.dart,test/codegen/async_helper.dart \
    package:async_helper/async_helper.dart

./bin/dartdevc.dart $SDK  -o gen/codegen_output/pkg/js.js \
    package:js/js.dart

./bin/dartdevc.dart $SDK  -o gen/codegen_output/pkg/matcher.js \
    package:matcher/matcher.dart

./bin/dartdevc.dart $SDK  -o gen/codegen_output/pkg/stack_trace.js \
    package:stack_trace/stack_trace.dart

./bin/dartdevc.dart $SDK  -o gen/codegen_output/pkg/path.js \
    package:path/path.dart

./bin/dartdevc.dart $SDK  -o gen/codegen_output/pkg/unittest.js \
    package:unittest/unittest.dart \
    package:unittest/html_config.dart \
    package:unittest/html_individual_config.dart \
    package:unittest/html_enhanced_config.dart
