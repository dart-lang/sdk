#!/usr/bin/env bash
# Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Script that collects progress metrics of the analyzer/FE integration.

# Metric 1: parser tests via fasta

# Run the suite to extract the total number of tests from the runner output.
# TODO(sigmund): don't require `dart` to be on the path.
total=$(dart pkg/analyzer/test/generated/parser_fasta_test.dart | \
  tail -1 | \
  sed -e "s/.*+\([0-9]*\)[^0-9].*All tests passed.*$/\1/")

# Count tests marked with the @failingTest annotation.
fail=$(cat pkg/analyzer/test/generated/parser_fasta_test.dart | \
  grep failingTest | wc -l)

pass_rate=$(bc <<< "scale=1; 100*($total-$fail)/$total")
echo "Parser-fasta tests:         $(($total - $fail))/$total ($pass_rate%)"

# Metric 2: analyzer tests with fasta enabled.

# Run analyzer tests forcing the fasta parser, then process the logged output to
# count the number of individual tests (a single test case in a test file) that
# are passing or failing.

echo "Analyzer tests files:"
logfile=$1
delete=0

# If a log file is provided on the command line, reuse it and don't run the
# suite again.
if [[ $logfile == '' ]]; then
  logfile=$(mktemp log-XXXXXX.txt)
  echo "  Log file: $logfile"
  # TODO: delete by default and stop logging the location of the file.
  # delete=1
  python tools/test.py -m release --checked --use-sdk \
     --vm-options="-DuseFastaParser=true" \
     pkg/analy > $logfile
fi;

pass=$(tail -1 $logfile | sed -e "s/.*+\s*\([0-9]*\) |.*$/\1/")
fail=$(tail -1 $logfile | sed -e "s/.* -\s*\([0-9]*\)\].*$/\1/")
pass_rate=$(bc <<< "scale=1; 100*$pass/($pass + $fail)")

echo "  Test files passing:       $pass/$(($pass + $fail)) ($pass_rate%)"

# Tests use package:test, which contains a summary line saying how many tests
# passed and failed. The line has this form:
#
#    MM:SS  +pp -ff: Some tests failed
#
# but also contains some escape sequences for color highlighting. The code below
# extracts the passing (pp) and failing (ff) numbers and tallies them up:
cat $logfile | \
  grep "Some tests failed" | \
  sed -e "s/.*+\([0-9]*\).* -\([0-9]*\).*/\1 \2/" | \
   awk '{
    pass += $1
    total += $1 + $2
  } END {
    printf ("  Individual tests passing: %d/%d (%.1f%)\n", \
      pass/2, total/2,(100 * pass / total))
  }'

if [[ $delete == 1 ]]; then
  echo "rm $logfile"
fi

# TODO: Add metric 3 - coverage of error codes
