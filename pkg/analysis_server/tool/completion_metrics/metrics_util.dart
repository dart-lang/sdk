// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/status/pages.dart';
import 'package:analyzer/src/generated/utilities_general.dart';

/// A simple counter class.  A [String] name is passed to name the counter. Each
/// time something is counted, a non-null, non-empty [String] key is passed to
/// [count] to increment the amount from zero. [printCounterValues] is provided
/// to have a [String] summary of the generated counts, example:
///
/// ```
/// Counts for 'counter example':
/// [bucket-1] 60 (60.0%)
/// [bucket-2] 25 (25.0%)
/// [bucket-3] 5 (5.0%)
/// [bucket-4] 10 (10.0%)
/// ```
class Counter {
  final String name;
  final Map<String, int> _buckets = {};
  int _totalCount = 0;

  Counter(this.name);

  /// Return a copy of all the current count data, this getter copies and
  /// returns the data to ensure that the data is only modified with the public
  /// accessors in this class.
  Map<String, int> get map => Map.from(_buckets);

  int get totalCount => _totalCount;

  void clear() {
    _buckets.clear();
    _totalCount = 0;
  }

  void count(String id, [int countNumber = 1]) {
    assert(id != null && id.isNotEmpty && 1 <= countNumber);
    if (_buckets.containsKey(id)) {
      _buckets[id] += countNumber;
    } else {
      _buckets.putIfAbsent(id, () => countNumber);
    }
    _totalCount += countNumber;
  }

  int getCountOf(String id) => _buckets[id] ?? 0;

  void printCounterValues() {
    print('Counts for \'$name\':');
    if (totalCount > 0) {
      _buckets.forEach((id, count) =>
          print('[$id] $count (${printPercentage(count / _totalCount, 2)})'));
    } else {
      print('<no counts>');
    }
  }
}

/// A computer for the mean reciprocal rank,
/// https://en.wikipedia.org/wiki/Mean_reciprocal_rank.
class MeanReciprocalRankComputer {
  final List<double> _ranks = [];
  MeanReciprocalRankComputer();

  double get mean {
    double sum = 0;
    _ranks.forEach((rank) {
      sum += rank;
    });
    return rankCount == 0 ? 0 : sum / rankCount;
  }

  int get rankCount => _ranks.length;

  int get ranks => _ranks.length;

  void addReciprocalRank(Place place) {
    _ranks.add(place.reciprocalRank);
  }

  void clear() => _ranks.clear();

  void printMean() {
    var mrr = mean;
    print('Mean Reciprocal Rank    = ${mrr.toStringAsFixed(5)}');
    print('Harmonic Mean (inverse) = ${(1 / mrr).toStringAsFixed(1)}');
  }
}

/// An immutable class to represent the placement in some list, for example '2nd
/// place out of 5'.
class Place {
  /// A 1-indexed place in a list
  final int _numerator;

  /// The total number of possible places.
  final int _denominator;

  const Place(this._numerator, this._denominator)
      : assert(_numerator > 0),
        assert(_denominator >= _numerator);

  const Place.none()
      : _numerator = 0,
        _denominator = 0;

  int get denominator => _denominator;

  @override
  int get hashCode => JenkinsSmiHash.hash2(_numerator, _denominator);

  int get numerator => _numerator;

  double get reciprocalRank => denominator == 0 ? 0 : numerator / denominator;

  @override
  bool operator ==(dynamic other) =>
      other is Place &&
      _numerator == other._numerator &&
      _denominator == other._denominator;
}
