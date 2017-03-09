// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

double average(List<double> elapsedTimes) {
  return elapsedTimes.reduce((v, e) => v + e) / elapsedTimes.length;
}

double standardDeviation(double mean, List<double> elapsedTimes) {
  double numerator = 0.0;
  for (double elapseTime in elapsedTimes) {
    numerator += (elapseTime - mean) * (elapseTime - mean);
  }
  double stdDev = sqrt(numerator / (elapsedTimes.length - 1));
  return stdDev;
}

double standardDeviationOfTheMean(List<double> elapsedTimes, double stdDev) {
  return stdDev / sqrt(elapsedTimes.length);
}
