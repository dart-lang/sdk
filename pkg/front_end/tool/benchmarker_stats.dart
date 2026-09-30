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

  /// For a paired comparison, the standard deviation of the per-pair
  /// differences; `null` for an unpaired comparison.
  final double? diffStdDev;

  new({
    required this.fromCount,
    required this.toCount,
    required this.fromMean,
    required this.toMean,
    required this.fromStdDev,
    required this.toStdDev,
    required this.diff,
    required this.confidence,
    this.diffStdDev,
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

/// Compares [from] and [to] as paired samples (`from[i]` and `to[i]` were
/// measured in the same round), using a two-sided paired t-test at the 95%
/// confidence level.
///
/// The test is done on the per-pair differences `to[i] - from[i]`, so
/// anything that affects both measurements in a pair equally (such as slow
/// drift in the machine's performance, when the runs are interleaved)
/// cancels out.
Comparison comparePaired(List<num> from, List<num> to) {
  if (from.length != to.length) {
    throw new ArgumentError(
      "Paired samples must have the same length "
      "(got ${from.length} and ${to.length}).",
    );
  }
  int count = from.length;
  List<num> diffs = [for (int i = 0; i < count; i++) to[i] - from[i]];
  double diffMean = SimpleTTestStat.average(diffs);
  double diffStdDev = math.sqrt(SimpleTTestStat.variance(diffs));
  double standardError = diffStdDev / math.sqrt(count);
  double confidence =
      SimpleTTestStat.tTableTwoTails_0_05(count - 1) * standardError;
  return new Comparison(
    fromCount: count,
    toCount: count,
    fromMean: SimpleTTestStat.average(from),
    toMean: SimpleTTestStat.average(to),
    fromStdDev: math.sqrt(SimpleTTestStat.variance(from)),
    toStdDev: math.sqrt(SimpleTTestStat.variance(to)),
    diff: diffMean,
    confidence: confidence,
    diffStdDev: diffStdDev,
  );
}

/// A linear trend fitted to a series of measurements.
class Trend {
  final int count;
  final double mean;

  /// The estimated change in the measurement per step (e.g. per round).
  final double slope;

  /// The half-width of the confidence interval for [slope].
  final double slopeConfidence;

  new({
    required this.count,
    required this.mean,
    required this.slope,
    required this.slopeConfidence,
  });

  /// The estimated total change from the first to the last measurement,
  /// expressed as a percentage of [mean], or `null` if [mean] is zero.
  double? get percentChangeOverSeries =>
      mean == 0 ? null : slope * (count - 1) * 100 / mean;

  /// The half-width of the confidence interval for
  /// [percentChangeOverSeries], or `null` if [mean] is zero.
  double? get percentConfidenceOverSeries =>
      mean == 0 ? null : (slopeConfidence * (count - 1) * 100 / mean).abs();

  /// Whether the confidence interval for [slope] excludes zero.
  bool get significant => slopeConfidence < slope.abs();
}

/// Fits a straight line to [values] (as a function of their index) using
/// least squares, and computes a 95% confidence interval for the slope.
///
/// This is used to detect drift, i.e. measurements getting steadily larger
/// or smaller over the course of a benchmarking session. Requires at least
/// three values.
Trend linearTrend(List<num> values) {
  int count = values.length;
  if (count < 3) {
    throw new ArgumentError("Need at least 3 values (got $count).");
  }
  double xMean = (count - 1) / 2;
  double yMean = SimpleTTestStat.average(values);
  double sxx = 0;
  double sxy = 0;
  for (int i = 0; i < count; i++) {
    double dx = i - xMean;
    sxx += dx * dx;
    sxy += dx * (values[i] - yMean);
  }
  double slope = sxy / sxx;
  double sse = 0;
  for (int i = 0; i < count; i++) {
    double residual = values[i] - (yMean + slope * (i - xMean));
    sse += residual * residual;
  }
  double residualVariance = sse / (count - 2);
  double slopeStandardError = math.sqrt(residualVariance / sxx);
  return new Trend(
    count: count,
    mean: yMean,
    slope: slope,
    slopeConfidence:
        SimpleTTestStat.tTableTwoTails_0_05(count - 2) * slopeStandardError,
  );
}
