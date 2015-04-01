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
DIFF_ARGS="-u -r -N --exclude=\*.map expect actual"

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
dart -c test/all_tests.dart || fail

# validate codegen_test output
pushd test/codegen/ &> /dev/null
rm -r actual/dev_compiler/ actual/sunflower/dev_compiler
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

echo -e "[32mAll tests pass[0m"
