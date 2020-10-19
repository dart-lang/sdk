// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:math' as math;

enum SortOrder {
  /// From fewest occurrences to most.
  ascending,

  /// From most occurrences to fewest.
  descending,

  /// Lexicographically sorted by name.
  alphabetical,

  /// Keys are parsed as integers and sorted by value.
  numeric,
}

/// Counts occurrences of strings and displays the results as a histogram.
class Histogram {
  final Map<Object, int> _counts = {};
  final SortOrder _order;
  final bool _showBar;
  final bool _showAll;
  final int _minCount;

  int get totalCount => _counts.values.fold(0, (a, b) => a + b);

  Histogram({SortOrder order, bool showBar, bool showAll, int minCount})
      : _order = order ?? SortOrder.descending,
        _showBar = showBar ?? true,
        _showAll = showAll ?? false,
        _minCount = minCount ?? 0;

  void add(Object item) {
    _counts.putIfAbsent(item, () => 0);
    _counts[item]++;
  }

  void printCounts(String label) {
    var total = totalCount;
    print('');
    print('-- $label ($total total) --');

    var keys = _counts.keys.toList();
    switch (_order) {
      case SortOrder.ascending:
        keys.sort((a, b) => _counts[a].compareTo(_counts[b]));
        break;
      case SortOrder.descending:
        keys.sort((a, b) => _counts[b].compareTo(_counts[a]));
        break;
      case SortOrder.alphabetical:
        keys.sort();
        break;
      case SortOrder.numeric:
        // TODO(rnystrom): Using string keys but treating them as integers is
        // kind of hokey. But it keeps the [ScrapeVisitor] API simpler.
        keys.sort((a, b) => (a as int).compareTo(b as int));
        break;
    }

    var longest = keys.fold<int>(
        0, (length, key) => math.max(length, key.toString().length));
    var barScale = 80 - 22 - longest;

    var shown = 0;
    var skipped = 0;
    for (var object in keys) {
      var count = _counts[object];
      var countString = count.toString().padLeft(7);
      var percent = 100 * count / total;
      var percentString = percent.toStringAsFixed(3).padLeft(7);

      if (_showAll || ((shown < 100 || percent >= 0.1) && count >= _minCount)) {
        var line = '$countString ($percentString%): $object';
        if (_showBar && barScale > 1) {
          line = line.padRight(longest + 22);
          line += '=' * (percent / 100 * barScale).ceil();
        }
        print(line);
        shown++;
      } else {
        skipped++;
      }
    }

    if (skipped > 0) print('And $skipped more less than 0.1%...');

    // If we're counting numeric keys, show other statistics too.
    if (_order == SortOrder.numeric && keys.isNotEmpty) {
      var sum = keys.fold<int>(
          0, (result, key) => result + (key as int) * _counts[key]);
      var average = sum / total;
      var median = _counts[keys[keys.length ~/ 2]];
      print('Sum $sum, average ${average.toStringAsFixed(3)}, median $median');
    }
  }
}
