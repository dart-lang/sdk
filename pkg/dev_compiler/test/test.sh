#!/bin/bash
set -e # bail on error

function fail {
  echo -e "[31mSome tests failed[0m"
  return 1
}

# Arguments passed to the diff tool. We exclude:
#  - *.map files so they aren't compared, as the diff is not human readable.
#  - runtime JS files that are just copied over from the sources and are not
#    duplicated in the expected folder.
DIFF_ARGS="-u -r -N --exclude=\*.map \
  --exclude=dart_runtime.js \
  --exclude=harmony_feature_check.js \
  --exclude=messages_widget.js \
  --exclude=messages.css \
  expect actual"

function show_diff {
  echo "Fail: actual output did not match expected"
  echo
  diff $DIFF_ARGS |\
    sed -e "s/^\(+.*\)/[32m\1[0m/" |\
    sed -e "s/^\(-.*\)/[31m\1[0m/"
  echo
  echo "You can update these expectations with:"
  echo "$ pushd `pwd` && cp -a actual/* expect && popd"
  fail
}

# the directory of this script
TEST_DIR=$( cd $( dirname "${BASH_SOURCE[0]}" ) && pwd )

# Some tests require being run from the package root
cd $TEST_DIR/..

# Check minimum SDK version
./tool/sdk_version_check.dart 1.9.0-dev.4.0 || fail

# Remove packages symlinks, and old codegen output
find test/codegen -name packages -exec rm {} \;
rm -r test/codegen/actual 2> /dev/null || true
find test/dart_codegen -name packages -exec rm {} \;
rm -r test/dart_codegen/actual 2> /dev/null || true
dart -c test/all_tests.dart || fail

# validate codegen_test output
pushd test/codegen/ &> /dev/null
diff $DIFF_ARGS > /dev/null || show_diff
popd &> /dev/null

# validate dart_codegen_test output
pushd test/dart_codegen/ &> /dev/null
diff $DIFF_ARGS > /dev/null || show_diff
popd &> /dev/null

# run self host and analyzer after other tests, because they're ~seconds to run.
dart -c test/checker/self_host_test.dart || fail

# Run analyzer on bin/devc.dart, as it includes most of the code we care about
# via transitive dependencies. This seems to be the only fast way to avoid
# repeated analysis of the same code.
# TODO(jmesserly): ideally we could do test/all_tests.dart, but
# dart_runtime_test.dart creates invalid generic type instantiation AA.
echo "Running dartanalyzer to check for errors/warnings/hints..."
dartanalyzer --fatal-warnings --package-warnings bin/devc.dart | (! grep $PWD) \
    || fail

{
  fc=`find test -name "*.dart" |\
      xargs grep "/\*\S* should be \S*\*/" | wc -l`
  echo "There are" $fc "tests marked as known failures."
}

# Run formatter in rewrite mode on all files that are part of the project.
# This checks that all files are commited first to git, so no state is lost.
# The formatter ignores:
#   * local files that have never been added to git,
#   * subdirectories of test/ and tool/, unless explicitly added. Those dirs
#     contain a lot of generated or external source we should not reformat.
(files=`git ls-files 'bin/*.dart' 'lib/*.dart' test/*.dart test/checker/*.dart \
  tool/*.dart | grep -v lib/src/js/`; git status -s $files | grep -q . \
  && echo "Did not run the formatter, please commit edited files first." \
  || (echo "Running dart formatter" ; pub run dart_style:format -w $files))
popd &> /dev/null

echo -e "[32mAll tests pass[0m"
