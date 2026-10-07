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
/// t-test at the `1 - alpha` confidence level (95% by default).
///
/// This uses the same formula as [SimpleTTestStat.ttest] (pooled standard
/// deviation, `n1 + n2 - 2` degrees of freedom), but exposes the details of
/// the comparison even when the result isn't significant.
Comparison compareUnpaired(
  List<num> from,
  List<num> to, {
  double alpha = 0.05,
}) {
  double fromMean = SimpleTTestStat.average(from);
  double toMean = SimpleTTestStat.average(to);
  double fromVariance = SimpleTTestStat.variance(from);
  double toVariance = SimpleTTestStat.variance(to);
  double pooledStandardDeviation = math.sqrt((fromVariance + toVariance) / 2);
  double pooledSampleStandardError =
      pooledStandardDeviation * math.sqrt(1 / from.length + 1 / to.length);
  double confidence =
      studentTCriticalValue(alpha, from.length + to.length - 2) *
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
/// measured in the same round), using a two-sided paired t-test at the
/// `1 - alpha` confidence level (95% by default).
///
/// The test is done on the per-pair differences `to[i] - from[i]`, so
/// anything that affects both measurements in a pair equally (such as slow
/// drift in the machine's performance, when the runs are interleaved)
/// cancels out.
Comparison comparePaired(List<num> from, List<num> to, {double alpha = 0.05}) {
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
  double confidence = studentTCriticalValue(alpha, count - 1) * standardError;
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
/// least squares, and computes a `1 - alpha` (95% by default) confidence
/// interval for the slope.
///
/// This is used to detect drift, i.e. measurements getting steadily larger
/// or smaller over the course of a benchmarking session. Requires at least
/// three values.
Trend linearTrend(List<num> values, {double alpha = 0.05}) {
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
        studentTCriticalValue(alpha, count - 2) * slopeStandardError,
  );
}

/// Returns how many of [samplesPerComparison] contain at least two
/// different values.
///
/// Each element of [samplesPerComparison] holds all the measurements for one
/// comparison (e.g. both the "from" and the "to" values for one metric). A
/// comparison whose measurements all have the exact same value is probably
/// constant for a structural reason (e.g. a counter that is always zero)
/// rather than by chance, so it carries no risk of a false positive, and
/// shouldn't count towards the Bonferroni correction.
int countNonConstant(Iterable<Iterable<num>> samplesPerComparison) {
  int count = 0;
  for (Iterable<num> samples in samplesPerComparison) {
    if (samples.isEmpty) continue;
    num first = samples.first;
    if (samples.any((v) => v != first)) count++;
  }
  return count;
}

/// Returns the significance level to use for each of [comparisons]
/// comparisons.
///
/// If [strict] is `true`, the Bonferroni correction is applied, so that the
/// chance of *any* false positive among the comparisons is at most 5%.
/// Otherwise each comparison is done at the 95% confidence level.
double perComparisonAlpha(int comparisons, {required bool strict}) {
  const double familyAlpha = 0.05;
  if (!strict || comparisons < 1) return familyAlpha;
  return familyAlpha / comparisons;
}

/// Returns the critical value `t` of Student's t-distribution with
/// [degreesOfFreedom] degrees of freedom for a two-sided test at
/// significance level [alpha], i.e. the `t` for which `P(|T| > t) = alpha`.
///
/// For example, `studentTCriticalValue(0.05, 10)` is about 2.228.
///
/// Unlike [SimpleTTestStat.tTableTwoTails_0_05], this supports any
/// significance level (needed for the Bonferroni correction), and is exact
/// for every number of degrees of freedom (the table rounds some of them).
double studentTCriticalValue(double alpha, int degreesOfFreedom) {
  if (degreesOfFreedom < 1) {
    throw new ArgumentError(
      "Degrees of freedom must be positive (got $degreesOfFreedom).",
    );
  }
  if (!(alpha > 0 && alpha < 1)) {
    throw new ArgumentError("alpha must be between 0 and 1 (got $alpha).");
  }
  double df = degreesOfFreedom.toDouble();
  // `studentTTwoSidedPValue` decreases as `t` increases, so find a `t` with
  // a p-value below alpha, and then bisect.
  double low = 0;
  double high = 1;
  while (studentTTwoSidedPValue(high, df) > alpha) {
    low = high;
    high *= 2;
  }
  for (int i = 0; i < 200 && high - low > 1e-13 * high; i++) {
    double mid = (low + high) / 2;
    if (studentTTwoSidedPValue(mid, df) > alpha) {
      low = mid;
    } else {
      high = mid;
    }
  }
  return (low + high) / 2;
}

/// Returns `P(|T| > t)` for Student's t-distribution with
/// [degreesOfFreedom] degrees of freedom.
double studentTTwoSidedPValue(double t, double degreesOfFreedom) {
  double x = degreesOfFreedom / (degreesOfFreedom + t * t);
  return regularizedIncompleteBeta(x, degreesOfFreedom / 2, 0.5);
}

/// The regularized incomplete beta function `I_x(a, b)`.
///
/// Only supports `a >= 0.5` and `b >= 0.5`, which is all that the
/// t-distribution needs (`a = degreesOfFreedom / 2`, `b = 0.5`).
double regularizedIncompleteBeta(double x, double a, double b) {
  if (!(a >= 0.5 && b >= 0.5)) {
    throw new ArgumentError("a and b must be at least 0.5 (got $a and $b).");
  }
  if (x <= 0) return 0;
  if (x >= 1) return 1;
  double logFront =
      _logGamma(a + b) -
      _logGamma(a) -
      _logGamma(b) +
      a * math.log(x) +
      b * math.log(1 - x);
  double front = math.exp(logFront);
  // The continued fraction converges quickly for x < (a + 1) / (a + b + 2);
  // otherwise use the symmetry I_x(a, b) = 1 - I_{1-x}(b, a).
  if (x < (a + 1) / (a + b + 2)) {
    return front * _betaContinuedFraction(x, a, b) / a;
  } else {
    return 1 - front * _betaContinuedFraction(1 - x, b, a) / b;
  }
}

/// Evaluates the continued fraction for the incomplete beta function using
/// the modified Lentz method (see "Numerical Recipes", section 6.4).
double _betaContinuedFraction(double x, double a, double b) {
  const int maxIterations = 10000;
  const double epsilon = 1e-15;
  const double tiny = 1e-300;
  double qab = a + b;
  double qap = a + 1;
  double qam = a - 1;
  double c = 1;
  double d = 1 - qab * x / qap;
  if (d.abs() < tiny) d = tiny;
  d = 1 / d;
  double h = d;
  for (int m = 1; m <= maxIterations; m++) {
    int m2 = 2 * m;
    double aa = m * (b - m) * x / ((qam + m2) * (a + m2));
    d = 1 + aa * d;
    if (d.abs() < tiny) d = tiny;
    c = 1 + aa / c;
    if (c.abs() < tiny) c = tiny;
    d = 1 / d;
    h *= d * c;
    aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2));
    d = 1 + aa * d;
    if (d.abs() < tiny) d = tiny;
    c = 1 + aa / c;
    if (c.abs() < tiny) c = tiny;
    d = 1 / d;
    double delta = d * c;
    h *= delta;
    if ((delta - 1).abs() < epsilon) break;
  }
  return h;
}

/// The natural logarithm of the gamma function, for `x >= 0.5`, using the
/// Lanczos approximation (g = 7, n = 9).
///
/// Smaller values would need the reflection formula, but nothing here needs
/// them (see [regularizedIncompleteBeta]).
double _logGamma(double x) {
  const List<double> coefficients = [
    0.99999999999980993,
    676.5203681218851,
    -1259.1392167224028,
    771.32342877765313,
    -176.61502916214059,
    12.507343278686905,
    -0.13857109526572012,
    9.9843695780195716e-6,
    1.5056327351493116e-7,
  ];
  x -= 1;
  double sum = coefficients[0];
  for (int i = 1; i < coefficients.length; i++) {
    sum += coefficients[i] / (x + i);
  }
  double t = x + 7.5;
  return 0.5 * math.log(2 * math.pi) +
      (x + 0.5) * math.log(t) -
      t +
      math.log(sum);
}
