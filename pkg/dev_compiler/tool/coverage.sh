#!/bin/bash
set -e # bail on error

# Prerequisite: ./tool/build_sdk.sh has been run.

# Install dart_coveralls; gather and send coverage data.
if [ "$COVERALLS_TOKEN" ] && [ "$TRAVIS_DART_VERSION" = "dev" ]; then
  echo "*** Running dart_coveralls"
  pub global run dart_coveralls report \
    --token $COVERALLS_TOKEN \
    --retry 2 \
    --throw-on-connectivity-error \
    --exclude-test-files \
    test/all_tests.dart
  echo "*** Done running dart_coveralls"
fi
