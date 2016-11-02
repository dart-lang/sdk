#!/bin/bash
set -e # bail on error

cd $( dirname "${BASH_SOURCE[0]}" )/..

mkdir -p gen/codegen_output/pkg/

SDK=--dart-sdk-summary=lib/sdk/ddc_sdk.sum

# Build leaf packages.  These have no other package dependencies.

# Under pkg

./bin/dartdevc.dart $SDK -o gen/codegen_output/pkg/async_helper.js \
    package:async_helper/async_helper.dart

./bin/dartdevc.dart $SDK -o gen/codegen_output/pkg/expect.js \
    package:expect/expect.dart \
    package:expect/minitest.dart

./bin/dartdevc.dart $SDK -o gen/codegen_output/pkg/js.js \
    package:js/js.dart \
    package:js/js_util.dart \

./bin/dartdevc.dart $SDK -o gen/codegen_output/pkg/lookup_map.js \
    package:lookup_map/lookup_map.dart

./bin/dartdevc.dart $SDK -o gen/codegen_output/pkg/meta.js \
    package:meta/meta.dart

./bin/dartdevc.dart $SDK -o gen/codegen_output/pkg/microlytics.js \
    package:microlytics/microlytics.dart \
    package:microlytics/html_channels.dart

./bin/dartdevc.dart $SDK -o gen/codegen_output/pkg/typed_mock.js \
    package:typed_mock/typed_mock.dart

# Under third_party/pkg

./bin/dartdevc.dart $SDK -o gen/codegen_output/pkg/args.js \
    package:args/args.dart \
    package:args/command_runner.dart

./bin/dartdevc.dart $SDK -o gen/codegen_output/pkg/charcode.js \
    package:charcode/charcode.dart

./bin/dartdevc.dart $SDK -o gen/codegen_output/pkg/collection.js \
    package:collection/collection.dart

./bin/dartdevc.dart $SDK -o gen/codegen_output/pkg/fixnum.js \
    package:fixnum/fixnum.dart

./bin/dartdevc.dart $SDK -o gen/codegen_output/pkg/logging.js \
    package:logging/logging.dart

./bin/dartdevc.dart $SDK -o gen/codegen_output/pkg/markdown.js \
    package:markdown/markdown.dart

./bin/dartdevc.dart $SDK -o gen/codegen_output/pkg/matcher.js \
    package:matcher/matcher.dart

./bin/dartdevc.dart $SDK -o gen/codegen_output/pkg/mime.js \
    package:mime/mime.dart

./bin/dartdevc.dart $SDK -o gen/codegen_output/pkg/path.js \
    package:path/path.dart

./bin/dartdevc.dart $SDK -o gen/codegen_output/pkg/plugin.js \
    package:plugin/plugin.dart \
    package:plugin/manager.dart

./bin/dartdevc.dart $SDK -o gen/codegen_output/pkg/typed_data.js \
    package:typed_data/typed_data.dart

./bin/dartdevc.dart $SDK -o gen/codegen_output/pkg/usage.js \
    package:usage/usage.dart

./bin/dartdevc.dart $SDK -o gen/codegen_output/pkg/utf.js \
    package:utf/utf.dart

./bin/dartdevc.dart $SDK -o gen/codegen_output/pkg/when.js \
    package:when/when.dart

# Composite packages with dependencies

./bin/dartdevc.dart $SDK -o gen/codegen_output/pkg/async.js \
   -s gen/codegen_output/pkg/collection.sum \
   package:async/async.dart

./bin/dartdevc.dart $SDK -o gen/codegen_output/pkg/stack_trace.js \
    -s gen/codegen_output/pkg/path.sum \
    package:stack_trace/stack_trace.dart
