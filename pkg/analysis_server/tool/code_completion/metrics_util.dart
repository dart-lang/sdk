// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:analysis_server/src/status/pages.dart';

import 'output_utilities.dart';

/// https://en.wikipedia.org/wiki/Average#Arithmetic_mean
class ArithmeticMeanComputer {
  final String name;
  int sum = 0;
  int count = 0;
  int? min;
  int? max;

  ArithmeticMeanComputer(this.name);

  double get mean => sum / count;

  /// Add the data from the given [computer] to this computer.
  void addData(ArithmeticMeanComputer computer) {
    sum += computer.sum;
    count += computer.count;
    min = _min(min, computer.min);
    max = _max(max, computer.max);
  }

  void addValue(int val) {
    sum += val;
    count++;
    min = _min(min, val);
    max = _max(max, val);
  }

  void clear() {
    sum = 0;
    count = 0;
  }

  /// Set the state of this computer to the state recorded in the decoded JSON
  /// [map].
  void fromJson(Map<String, dynamic> map) {
    sum = map['sum'] as int;
    count = map['count'] as int;
    min = map['min'] as int?;
    max = map['max'] as int?;
  }

  /// Return a map used to represent this computer in a JSON structure.
  Map<String, dynamic> toJson() {
    return {
      'sum': sum,
      'count': count,
      if (min != null) 'min': min,
      if (max != null) 'max': max,
    };
  }

  int? _max(int? first, int? second) {
    if (first == null) {
      return second;
    } else if (second == null) {
      return first;
    } else {
      return math.max(first, second);
    }
  }

  int? _min(int? first, int? second) {
    if (first == null) {
      return second;
    } else if (second == null) {
      return first;
    } else {
      return math.min(first, second);
    }
  }
}

/// A simple counter class. A [String] name is passed to name the counter. Each
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

  /// Add the data from the given [counter] to this counter.
  void addData(Counter counter) {
    for (var entry in counter._buckets.entries) {
      var bucket = entry.key;
      _buckets[bucket] = (_buckets[bucket] ?? 0) + entry.value;
    }
    _totalCount += counter._totalCount;
  }

  void clear() {
    _buckets.clear();
    _totalCount = 0;
  }

  void count(String id, [int countNumber = 1]) {
    assert(id.isNotEmpty && 1 <= countNumber);
    _buckets.update(
      id,
      (value) => value + countNumber,
      ifAbsent: () => countNumber,
    );
    _totalCount += countNumber;
  }

  /// Set the state of this counter to the state recorded in the decoded JSON
  /// [map].
  void fromJson(Map<String, dynamic> map) {
    for (var entry in (map['buckets'] as Map<String, dynamic>).entries) {
      _buckets[entry.key] = entry.value as int;
    }
    _totalCount = map['totalCount'] as int;
  }

  int getCountOf(String id) => _buckets[id] ?? 0;

  void printCounterValues() {
    if (_totalCount > 0) {
      var table = [
        ['', 'count', 'percent']
      ];
      var entries = _buckets.entries.toList();
      entries.sort((first, second) => second.value - first.value);
      for (var entry in entries) {
        var id = entry.key;
        var count = entry.value;
        table.add(
            [id, count.toString(), printPercentage(count / _totalCount, 2)]);
      }
      printTable(table);
    } else {
      print('<no counts>');
    }
  }

  /// Return a map used to represent this counter in a JSON structure.
  Map<String, dynamic> toJson() {
    return {
      'buckets': _buckets,
      'totalCount': _totalCount,
    };
  }
}

class DistributionComputer {
  /// The buckets in which values are counted: [0..9], [10..19], ... [100..].
  List<int> buckets = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  /// Add the data from the given [computer] to this computer.
  void addData(DistributionComputer computer) {
    for (var i = 0; i < buckets.length; i++) {
      buckets[i] += computer.buckets[i];
    }
  }

  /// Add a millisecond value to the list of buckets.
  void addValue(int value) {
    var bucket = math.min(value ~/ 10, buckets.length - 1);
    buckets[bucket]++;
  }

  /// Return a textual representation of the distribution.
  String displayString() {
    var buffer = StringBuffer();
    for (var i = 0; i < buckets.length; i++) {
      if (i > 0) {
        buffer.write(' ');
      }
      buffer.write('[');
      buffer.write(i * 10);
      buffer.write('] ');
      buffer.write(buckets[i]);
    }
    return buffer.toString();
  }

  /// Set the state of this computer to the state recorded in the decoded JSON
  /// [map].
  void fromJson(Map<String, dynamic> map) {
    buckets = map['buckets'] as List<int>;
  }

  /// Return a map used to represent this computer in a JSON structure.
  Map<String, dynamic> toJson() {
    return {
      'buckets': buckets,
    };
  }
}

/// A computer for the mean reciprocal rank. The MRR as well as the MRR only
/// if the item was in the top 5 in the list see [MAX_RANK], is computed.
/// https://en.wikipedia.org/wiki/Mean_reciprocal_rank.
class MeanReciprocalRankComputer {
  static final int MAX_RANK = 5;
  final String name;
  double _sum = 0;
  double _sum_5 = 0;
  int _count = 0;

  MeanReciprocalRankComputer(
    this.name,
  );

  int get count => _count;

  double get mrr {
    if (count == 0) {
      return 0;
    }
    return _sum / count;
  }

  double get mrr_5 {
    if (count == 0) {
      return 0;
    }
    return _sum_5 / count;
  }

  /// Add the data from the given [computer] to this computer.
  void addData(MeanReciprocalRankComputer computer) {
    _sum += computer._sum;
    _sum_5 += computer._sum_5;
    _count += computer._count;
  }

  void addRank(int rank) {
    if (rank != 0) {
      _sum += 1 / rank;
      if (rank <= MAX_RANK) {
        _sum_5 += 1 / rank;
      }
    }
    _count++;
  }

  void clear() {
    _sum = 0;
    _sum_5 = 0;
    _count = 0;
  }

  /// Set the state of this computer to the state recorded in the decoded JSON
  /// [map].
  void fromJson(Map<String, dynamic> map) {
    _sum = map['sum'] as double;
    _sum_5 = map['sum_5'] as double;
    _count = map['count'] as int;
  }

  void printMean() {
    print('Mean Reciprocal Rank \'$name\' (total = $count)');
    print('mrr   = ${mrr.toStringAsFixed(6)} '
        '(inverse = ${(1 / mrr).toStringAsFixed(3)})');

    print('mrr_5 = ${mrr_5.toStringAsFixed(6)} '
        '(inverse = ${(1 / mrr_5).toStringAsFixed(3)})');
  }

  /// Return a map used to represent this computer in a JSON structure.
  Map<String, dynamic> toJson() {
    return {
      'sum': _sum,
      'sum_5': _sum_5,
      'count': _count,
    };
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

  /// Return an instance extracted from the decoded JSON [map].
  factory Place.fromJson(Map<String, dynamic> map) {
    return Place(map['numerator'] as int, map['denominator'] as int);
  }

  const Place.none()
      : _numerator = 0,
        _denominator = 0;

  int get denominator => _denominator;

  @override
  int get hashCode => Object.hash(_numerator, _denominator);

  int get numerator => _numerator;

  int get rank => _numerator;

  @override
  bool operator ==(dynamic other) =>
      other is Place &&
      _numerator == other._numerator &&
      _denominator == other._denominator;

  /// Return a map used to represent this place in a JSON structure.
  Map<String, dynamic> toJson() {
    return {
      'numerator': _numerator,
      'denominator': _denominator,
    };
  }
}
