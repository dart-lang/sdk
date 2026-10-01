// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Statistics used by `benchmarker.dart`.
library;

import 'dart:math' as math;

import '../test/simple_stats.dart';

/// The result of comparing the measurements of a single metric for two
/// snapshots ("from" and "to").
class Comparison {
  final int fromCount;
  final int toCount;
  final double fromMean;
  final double toMean;
  final double fromStdDev;
  final double toStdDev;

  /// The estimated change in the metric, i.e. `mean(to) - mean(from)`.
  final double diff;

  /// The half-width of the confidence interval for [diff].
  final double confidence;

  new({
    required this.fromCount,
    required this.toCount,
    required this.fromMean,
    required this.toMean,
    required this.fromStdDev,
    required this.toStdDev,
    required this.diff,
    required this.confidence,
  });

  /// [confidence] expressed as a percentage of [fromMean], or `null` if
  /// [fromMean] is zero.
  double? get percentConfidence =>
      fromMean == 0 ? null : confidence * 100 / fromMean;

  /// [diff] expressed as a percentage of [fromMean], or `null` if [fromMean]
  /// is zero.
  double? get percentDiff => fromMean == 0 ? null : diff * 100 / fromMean;

  /// Whether the confidence interval for [diff] excludes zero.
  bool get significant => confidence < diff.abs();
}

/// Compares [from] and [to] as two independent samples, using a two-sided
/// t-test at the 95% confidence level.
///
/// This uses the same formula as [SimpleTTestStat.ttest] (pooled standard
/// deviation, `n1 + n2 - 2` degrees of freedom), but exposes the details of
/// the comparison even when the result isn't significant.
Comparison compareUnpaired(List<num> from, List<num> to) {
  double fromMean = SimpleTTestStat.average(from);
  double toMean = SimpleTTestStat.average(to);
  double fromVariance = SimpleTTestStat.variance(from);
  double toVariance = SimpleTTestStat.variance(to);
  double pooledStandardDeviation = math.sqrt((fromVariance + toVariance) / 2);
  double pooledSampleStandardError =
      pooledStandardDeviation * math.sqrt(1 / from.length + 1 / to.length);
  double confidence =
      SimpleTTestStat.tTableTwoTails_0_05(from.length + to.length - 2) *
      pooledSampleStandardError;
  return new Comparison(
    fromCount: from.length,
    toCount: to.length,
    fromMean: fromMean,
    toMean: toMean,
    fromStdDev: math.sqrt(fromVariance),
    toStdDev: math.sqrt(toVariance),
    diff: toMean - fromMean,
    confidence: confidence,
  );
}
