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
    print('Counts for \'$name\' (total = $_totalCount):');
    if (_totalCount > 0) {
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
  final String name;
  final List<int> ranks = [];
  MeanReciprocalRankComputer(this.name);

  double getMRR([int maxRank = 0]) {
    if (ranks.isEmpty || maxRank < 0) {
      return 0;
    }
    double sum = 0;
    ranks.forEach((rank) {
      if (maxRank == 0) {
        if (rank != 0) {
          sum += 1 / rank;
        }
      } else {
        if (rank != 0 && rank <= maxRank) {
          sum += 1 / rank;
        }
      }
    });
    return sum / rankCount;
  }

  int get rankCount => ranks.length;

  void addRank(int rank) {
    ranks.add(rank);
  }

  void clear() => ranks.clear();

  void printMean() {
    var mrrVal = getMRR();
    print('Mean Reciprocal Rank \'$name\' (total = $rankCount)');
    print('mmr   = ${mrrVal.toStringAsFixed(6)} '
        '(inverse = ${(1 / mrrVal).toStringAsFixed(3)})');

    var mrrVal5 = getMRR(5);
    print('mmr_5 = ${mrrVal5.toStringAsFixed(6)} '
        '(inverse = ${(1 / mrrVal5).toStringAsFixed(3)})');
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

  int get rank => _numerator;

  @override
  bool operator ==(dynamic other) =>
      other is Place &&
      _numerator == other._numerator &&
      _denominator == other._denominator;
}
