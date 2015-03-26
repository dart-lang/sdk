#!/bin/bash

# Fast fail the script on failures.
set -e

function clean {
  # This is a much simpler clean script, assuming git is available
  pushd test
  git clean -fdx
  popd
  pub install
}

clean

dart --checked test/all_tests.dart

# Install dart_coveralls; gather and send coverage data.
if [ "$COVERALLS_TOKEN" ]; then
  clean

  pub global run dart_coveralls report \
    --token $COVERALLS_TOKEN \
    --retry 2 \
    --exclude-test-files \
    test/all_tests.dart
fi
