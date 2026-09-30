// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:expect/expect.dart';

import '../tool/benchmarker_stats.dart';
import 'simple_stats.dart';

void main() {
  testCompareUnpairedMatchesSimpleTTestStat();
  testCompareUnpairedNotSignificant();
  testCompareUnpairedZeroMean();
  testComparePairedKnownValues();
  testComparePairedCancelsDrift();
  testComparePairedLengthMismatch();
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

void testComparePairedKnownValues() {
  List<num> from = [10, 20, 30, 40, 50];
  List<num> to = [11, 22, 31, 43, 52];
  Comparison comparison = comparePaired(from, to);
  // The differences are [1, 2, 1, 3, 2]: mean 1.8, sample variance 0.7.
  expectClose(1.8, comparison.diff);
  expectClose(math.sqrt(0.7), comparison.diffStdDev!);
  // t(0.975, df = 4) * sd / sqrt(n).
  expectClose(2.776445105 * math.sqrt(0.7 / 5), comparison.confidence);
  Expect.isTrue(comparison.significant);
  Expect.equals(5, comparison.fromCount);
  Expect.equals(5, comparison.toCount);
  expectClose(30, comparison.fromMean);
  expectClose(31.8, comparison.toMean);
  expectClose(6, comparison.percentDiff!);
  // The large spread between rounds hides the difference from the unpaired
  // test.
  Expect.isFalse(compareUnpaired(from, to).significant);
  Expect.isNull(compareUnpaired(from, to).diffStdDev);
}

void testComparePairedCancelsDrift() {
  // Both snapshots are affected by the same slow drift (e.g. the machine
  // getting slower over the session), and there's no real difference
  // between them apart from a little noise.
  List<num> noiseFrom = [0.3, -0.2, 0.1, -0.4, 0.2, 0.0, -0.1, 0.3];
  List<num> noiseTo = [-0.1, 0.2, -0.3, 0.1, 0.0, 0.3, -0.2, 0.1];
  List<num> from = [for (int i = 0; i < 8; i++) 100 + 2 * i + noiseFrom[i]];
  List<num> to = [for (int i = 0; i < 8; i++) 100 + 2 * i + noiseTo[i]];
  Comparison comparison = comparePaired(from, to);
  Expect.isFalse(comparison.significant);
  // The per-pair differences are small, even though the values themselves
  // vary a lot.
  Expect.isTrue(comparison.diffStdDev! < 1);
  Expect.isTrue(comparison.fromStdDev > 4);
}

void testComparePairedLengthMismatch() {
  Expect.throws<ArgumentError>(() => comparePaired([1, 2, 3], [1, 2]));
}
