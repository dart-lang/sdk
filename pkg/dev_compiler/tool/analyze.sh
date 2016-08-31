#!/bin/bash
set -e

# Switch to the root directory of dev_compiler
cd $( dirname "${BASH_SOURCE[0]}" )/..

function fail {
  echo -e "[31mAnalyzer found problems[0m"
  return 1
}

# Run analyzer on bin/dartdevc.dart, as it includes most of the code we care
# about via transitive dependencies. This seems to be the only fast way to avoid
# repeated analysis of the same code.
# TODO(jmesserly): ideally we could do test/all_tests.dart, but
# dart_runtime_test.dart creates invalid generic type instantiation AA.
echo "Running dartanalyzer to check for errors/warnings/hints..."
dartanalyzer --strong --fatal-warnings --package-warnings \
    bin/dartdevc.dart web/main.dart \
    | grep -v "\[info\] TODO" | (! grep $PWD) || fail
