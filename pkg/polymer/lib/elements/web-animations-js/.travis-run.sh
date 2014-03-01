#! /bin/bash

set -x

if [ x$MODE == x'check' ]; then
  SUCCESS=0

  # Check that the testcases json file has been updated
  echo "Checking test cases is up to date..."
  python ./test/update-testcases.py --dry-run
  let "SUCCESS += $?"

  # Check that the web-animations.js file passes lint checks
  ./run-lint.sh
  let "SUCCESS += $?"

  exit $SUCCESS
else
  # For pull requests we don't have access to secure environment variables, so we just return true.
  if [ x$BROWSER == "xRemote" -a x$SAUCE_ACCESS_KEY == x"" ]; then
    exit 0
  fi

  if [ x$BROWSER == "xAndroid-Chrome" ]; then
    echo ./run-tests-android.sh $ARGS | bash || exit 1
  else
    echo ./run-tests.sh $ARGS | bash || exit 1
  fi
fi
