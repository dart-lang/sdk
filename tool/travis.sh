#!/bin/bash

# Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Fast fail the script on failures.
set -e

if [ "$LINTER_BOT" = "release" ]; then
  echo "Validating release..."
  dart tool/bot/version_check.dart
  dart tool/bot/rule_doc_check.dart

# https://github.com/dart-lang/linter/issues/2014
#elif [ "$LINTER_BOT" = "score" ]; then
#
#  # Scorecard generation is best effort; don't fail the build.
#  set +e
#  echo ""
#  echo ""
#  echo "Generating scorecard..."
#  echo ""
#  dart tool/scorecard.dart

elif [ "$LINTER_BOT" = "benchmark" ]; then
  echo "Running the linter benchmark..."

  # The actual lints can have errors - we don't want to fail the benchmark bot.
  set +e

  # Benchmark linter with all lints enabled.
  dart bin/linter.dart --benchmark -q -c example/all.yaml .

  # Check for errors encountered during analysis / benchmarking and fail as appropriate.
  if [ $? -eq 63 ];  then
    echo ""
    echo "Error occurred while benchmarking"
    exit 1
  fi

elif [ "$LINTER_BOT" = "pana_baseline" ]; then
  echo "Checking the linter pana baseline..."

  dart tool/pana_baseline.dart

else
  echo "Running main linter bot"

  # Verify that the libraries are error free.
  dart analyze --fatal-infos .

  echo ""

  # Install dart_coveralls; gather and send coverage data.
  if [ "$COVERALLS_TOKEN" ]; then

    OBS_PORT=9292
    
    # Run the tests setup for coverage reporting.
    dart --disable-service-auth-codes \
      --disable-analytics \
      --enable-vm-service=$OBS_PORT \
      --pause-isolates-on-exit \
      test/all.dart &

    status=$?  

    pub global activate coverage

    echo "Collecting coverage on port $OBS_PORT..."

    # Run the coverage collector to generate the JSON coverage report.
    collect_coverage \
      --port=$OBS_PORT \
      --out=var/coverage.json \
      --wait-paused \
      --resume-isolates

    echo "Generating LCOV report..."
    format_coverage \
      --lcov \
      --in=var/coverage.json \
      --out=var/lcov.info \
      --packages=.packages \
      --report-on=lib \
      --check-ignore

    echo "Running coveralls..."
    gem install coveralls-lcov
    coveralls-lcov var/lcov.info

    exit $status
  else
    # Run the tests w/o coverage
    dart --disable-analytics \
      test/all.dart
  fi
fi
