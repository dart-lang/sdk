#!/bin/bash
#
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This file is repsonsible for performing the averag and standard deviation
# for a specific metrics over a given set of metrics in a file.
# This should be included in other compiler scripts, or used through
# sample_metrics.sh

AVERAGE=0
STDEV=0
COUNT=0

function do_math_return() {
  local sum=0
  local count=0
  local time
  for time in $2
  do
    sum=$(echo "$sum + $time" | bc -l)
    (( count++ ))
  done
  average=$(echo "$sum / $count" | bc -l)
  #echo "count=$count, sum=$sum, average=$average"

  #go over the numbers, take the difference from the average and squart, then square root / count.
  sum_dev=0
  for time in $2
  do
    step=$(echo "$time - $average" | bc -l)
    sum_dev=$(echo "$sum_dev + $step^2" | bc -l)
  done

    step=$(echo "$sum_dev / $count" | bc -l)
  OUT="sqrt(${step})"
  standard_dev=$(echo $OUT | bc -l | sed 's/\([0-9]*\.[0-9][0-9]\)[0-9]*/\1/')
  average=$(echo $average | sed 's/\([0-9]*\.[0-9][0-9]\)[0-9]*/\1/')
  AVERAGE=$average
  STDEV=$standard_dev
  COUNT=$count
}

function do_math() {
  do_math_return "$1" "$2"
  echo "$1: average: $AVERAGE stdev: $STDEV count: $COUNT"
}

function sample_file_return() {
  TIMES=$(sed -n "s/$2\S*\s*:\s*\(\([0-9]*\)\(\.[0-9]*\)\?\)/\1/p" $3)
  do_math_return "$1" "$TIMES"
  SAMPLE_LINE="$1: average: $AVERAGE stdev: $STDEV count: $COUNT"
}

function sample_file() {
  TIMES=$(sed -n "s/$2\S*\s*:\s*\(\([0-9]*\)\(\.[0-9]*\)\?\)/\1/p" $3)
  do_math "$1" "$TIMES"
}
