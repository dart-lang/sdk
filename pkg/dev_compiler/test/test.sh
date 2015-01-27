#!/bin/bash
set -e # bail on error

function fail {
  echo -e "[31mSome tests failed[0m"
  return 1
}

function show_diff {
  echo "Fail: actual output did not match expected"
  echo
  diff -u -r -N $1 $2 |\
    sed -e "s/^\(+.*\)/[32m\1[0m/" |\
    sed -e "s/^\(-.*\)/[31m\1[0m/"
  echo
  echo "You can update these expectations with:"
  echo "$ pushd $TEST_DIR/codegen"
  echo "$ cp -a actual/* expect"
  echo "$ popd"
  fail
}

# the directory of this script 
TEST_DIR=$( cd $( dirname "${BASH_SOURCE[0]}" ) && pwd )

# Some tests require being run from the package root
pushd $TEST_DIR/.. &> /dev/null

# Remove packages symlinks, and old codegen output
find test/codegen -name packages -exec rm {} \;
rm -r test/codegen/actual > /dev/null || true
dart -c test/all_tests.dart || fail

# validate codegen_test output
pushd test/codegen/ &> /dev/null
diff -u -r -N expect actual > /dev/null || show_diff expect actual
popd &> /dev/null

# run self host and analyzer after other tests, because they're ~seconds to run.
dart -c test/checker/self_host_test.dart || fail

ls lib/*.dart bin/*.dart | dartanalyzer -b --fatal-warnings || fail
{
  fc=`find test -name "*.dart" |\
      xargs grep "/\*\S* should be \S*\*/" | wc -l`
  echo "There are" $fc "tests marked as known failures."
}

# Run formatter on all files that are part of the project. This checks that all
# files are commited first. This also ignores local files that have never been
# added to the git repo.
(files=`git ls-files "*.dart"`; git status -s $files | grep -q . \
  && echo "Did not run the formatter, please commit edited files first." \
  || (echo "Running dart formatter" ; pub run dart_style:format -w $files))
popd &> /dev/null

echo -e "[32mAll tests pass[0m"
