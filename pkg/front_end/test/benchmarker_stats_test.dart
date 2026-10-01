// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import '../tool/benchmarker_stats.dart';
import 'simple_stats.dart';

void main() {
  testCompareUnpairedMatchesSimpleTTestStat();
  testCompareUnpairedNotSignificant();
  testCompareUnpairedZeroMean();
}

void expectClose(double expected, double actual, {double epsilon = 1e-9}) {
  Expect.isTrue(
    (expected - actual).abs() <= epsilon * (1 + expected.abs()),
    "Expected $expected but got $actual",
  );
}

void testCompareUnpairedMatchesSimpleTTestStat() {
  List<num> from = [100, 102, 98, 101, 99];
  List<num> to = [110, 111, 109, 112, 108];
  Comparison comparison = compareUnpaired(from, to);
  // SimpleTTestStat.ttest takes its arguments in the opposite order.
  TTestResult expected = SimpleTTestStat.ttest(to, from);
  Expect.isTrue(expected.significant);
  Expect.isTrue(comparison.significant);
  expectClose(expected.diff, comparison.diff);
  expectClose(expected.confidence, comparison.confidence);
  expectClose(expected.percentDiff, comparison.percentDiff!);
  expectClose(expected.percentDiffConfidence, comparison.percentConfidence!);
  expectClose(expected.aMean, comparison.toMean);
  expectClose(expected.bMean, comparison.fromMean);
  Expect.equals(5, comparison.fromCount);
  Expect.equals(5, comparison.toCount);
  expectClose(1.5811388300841898, comparison.fromStdDev);
  expectClose(1.5811388300841898, comparison.toStdDev);
}

void testCompareUnpairedNotSignificant() {
  List<num> from = [100, 110, 90, 105, 95];
  List<num> to = [101, 111, 91, 106, 96];
  Comparison comparison = compareUnpaired(from, to);
  Expect.isFalse(SimpleTTestStat.ttest(to, from).significant);
  Expect.isFalse(comparison.significant);
  // Unlike TTestResult, the details are still available.
  expectClose(1.0, comparison.diff);
  expectClose(1.0, comparison.percentDiff!);
  Expect.isTrue(comparison.confidence > 1.0);
}

void testCompareUnpairedZeroMean() {
  Comparison comparison = compareUnpaired([0, 0, 0], [0, 0, 0]);
  Expect.isFalse(comparison.significant);
  Expect.isNull(comparison.percentDiff);
  Expect.isNull(comparison.percentConfidence);
}
