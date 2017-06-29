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

# Delete codegen expectation files to be sure that if a test fails to compile
# we don't erroneously pick up the old version.
if [ -d test/codegen/expect ]; then
  rm -r test/codegen/expect || fail
fi

if [ -d gen/codegen_input ]; then
  rm -r gen/codegen_input || fail
fi

if [ -d gen/codegen_output ]; then
  rm -r gen/codegen_output || fail
fi

./tool/build_test_pkgs.sh

# Make sure we don't run tests in code coverage mode.
# this will cause us to generate files that are not part of the baseline
# TODO(jmesserly): we should move diff into Dart code, so we don't need to
# worry about this. Also if we're in code coverage mode, we should avoid running
# all_tests twice. Finally self_host_test is not currently being tracked by
# code coverage.
unset COVERALLS_TOKEN
dart test/all_tests.dart || fail

{
  fc=`find test -name "*.dart" |\
      xargs grep "/\*\S* should be \S*\*/" | wc -l`
  echo "There are" $fc "tests marked as known failures."
}

echo -e "[32mAll tests built - run tool/browser_test.sh to run tests[0m"
