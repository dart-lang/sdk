// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A range of indexes within a list.
class IndexRange {
  /// The index of the first element in the range.
  final int lower;

  /// The index of the last element in the range. This will be the same as the
  /// [lower] if there is a single element in the range.
  final int upper;

  /// Initialize a newly created range.
  IndexRange(this.lower, this.upper);

  /// Return the number of indices in this range.
  int get count => upper - lower + 1;

  @override
  String toString() => '[$lower..$upper]';

  static List<IndexRange> contiguousSubRanges(List<int> indexes) {
    var ranges = <IndexRange>[];
    if (indexes.isEmpty) {
      return ranges;
    }
    var lower = indexes[0];
    var previous = lower;
    for (var index = 1; index < indexes.length; index++) {
      var current = indexes[index];
      if (current == previous + 1) {
        previous = current;
      } else {
        ranges.add(IndexRange(lower, previous));
        lower = previous = current;
      }
    }
    ranges.add(IndexRange(lower, previous));
    return ranges;
  }
}
