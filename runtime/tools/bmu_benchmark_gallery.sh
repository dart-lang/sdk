#!/usr/bin/env bash
#
# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Wrapper that runs a given Dart VM over the benchmarks with --verbose_gc
# and uses the verbose_gc_to_bmu script to produce a gallery of BMU graphs.

if [ "$#" -ne 3 ]
then
    echo "Usage: $0 dart_binary benchmark_directory output_directory"
    echo "Example: $0 out/ReleaseIA32/dart ../golem4/benchmarks /tmp/bmu"
    exit 1
fi

DART_BIN=$1
BENCH_DIR=$2
OUT_DIR=$3

VERBOSE_GC_TO_BMU=$(dirname "$0")/verbose_gc_to_bmu.dart
INDEX_FILE=$OUT_DIR/index.html
TMP=/tmp/bmu_benchmark_gallery

mkdir -p $OUT_DIR
echo "<html><body>" > $INDEX_FILE
$DART_BIN --version 2>> $INDEX_FILE
echo "<br>" >> $INDEX_FILE
for NAME in `ls $BENCH_DIR`
do
    $DART_BIN --verbose_gc $BENCH_DIR/$NAME/dart/$NAME.dart 2> $TMP.gclog &&
    $DART_BIN $VERBOSE_GC_TO_BMU < $TMP.gclog > $TMP.dat &&
    gnuplot -e "set term png; set output '$TMP.png'; set title '$NAME'; set ylabel 'BMU'; set xlabel 'Window size (ms)'; unset key; set yr [0:1]; set logscale x; plot '$TMP.dat' with linespoints" &&
    mv -f $TMP.png $OUT_DIR/$NAME.png &&
    mv -f $TMP.gclog $OUT_DIR/$NAME.txt &&
    echo "<a href='$NAME.txt'><img src='$NAME.png'></a>" >> $INDEX_FILE
done
echo "</body></html>" >> $INDEX_FILE
