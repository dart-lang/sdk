// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:front_end/src/fasta/outline.dart' as outline;

import 'standard_deviation.dart';

const int iterations = const int.fromEnvironment("iterations", defaultValue: 1);

main(List<String> arguments) async {
  // Timing results for each iteration
  List<double> elapseTimes = <double>[];

  for (int i = 0; i < iterations; i++) {
    if (i > 0) {
      print("\n");
    }

    var stopwatch = new Stopwatch()..start();
    await outline.compile(arguments);
    stopwatch.stop();

    elapseTimes.add(stopwatch.elapsedMilliseconds.toDouble());
  }

  // No summary if less than 4 iterations
  if (elapseTimes.length < 4) {
    return;
  }

  // Calculate the mean of warm runs (#4 to n)
  List<double> warmTimes = elapseTimes.sublist(3);
  double mean = average(warmTimes);

  // Calculate the standard deviation
  double stdDev = standardDeviation(mean, warmTimes);

  // Calculate the standard deviation of the mean
  double stdDevOfTheMean = standardDeviationOfTheMean(warmTimes, stdDev);

  print('Summary:');
  print('  Elapse times: $elapseTimes');
  print('  Cold start (first run): ${elapseTimes[0]}');
  print('  Warm run average (runs #4 to #$iterations): $mean');
  print('  Warm run standard deviation of the mean: $stdDevOfTheMean');
}
