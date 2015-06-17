#!/bin/bash
set -e # bail on error

function fail {
  echo -e "[31mSome tests failed[0m"
  return 1
}

# Some tests require being run from the package root
# switch to the root directory of dev_compiler
cd $( dirname "${BASH_SOURCE[0]}" )/..

# Check minimum SDK version
./tool/sdk_version_check.dart 1.9.0-dev.4.0 || fail

# Make sure we don't run tests in code coverage mode.
# this will cause us to generate files that are not part of the baseline
# TODO(jmesserly): we should move diff into Dart code, so we don't need to
# worry about this. Also if we're in code coverage mode, we should avoid running
# all_tests twice. Finally self_host_test is not currently being tracked by
# code coverage.
unset COVERALLS_TOKEN
pub run test:test test/all_tests.dart || fail

# run self host and analyzer after other tests, because they're ~seconds to run.
pub run test:test test/checker/self_host_test.dart || fail

{
  fc=`find test -name "*.dart" |\
      xargs grep "/\*\S* should be \S*\*/" | wc -l`
  echo "There are" $fc "tests marked as known failures."
}

echo -e "[32mAll tests pass[0m"
