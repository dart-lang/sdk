// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A range of probabilities that a given event has occurred.
class ProbabilityRange {
  /// The lower bound of the range.
  final double lower;

  /// The upper bound of the range.
  final double upper;

  /// Initialize a newly created probability range to have the given [lower] and
  /// [upper] bounds.
  const ProbabilityRange({this.lower, this.upper});

  /// Given the [probability] of an occurrence of an event that is conditional
  /// on the event represented by this range, return the probability of the
  /// event independent of the event based on this range.
  double conditionalProbability(double probability) {
    return lower + ((upper - lower) * probability);
  }
}
