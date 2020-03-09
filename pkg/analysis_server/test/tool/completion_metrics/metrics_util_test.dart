// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../../../tool/completion_metrics/metrics_util.dart';

void main() {
  group('Counter', () {
    test('empty', () {
      var counter = Counter('empty');
      expect(counter.map, isEmpty);
      expect(counter.totalCount, equals(0));
    });

    test('clear', () {
      var counter = Counter('name');
      counter.count('bucket-1', 1);
      expect(counter.map, isNotEmpty);
      expect(counter.totalCount, equals(1));

      counter.clear();
      expect(counter.map, isEmpty);
      expect(counter.totalCount, equals(0));
    });

    test('getCountOf', () {
      var counter = Counter('name');
      counter.count('bucket-1', 1);
      counter.count('bucket-2', 1);
      counter.count('bucket-2', 1);
      counter.count('bucket-3', 3);
      expect(counter.name, equals('name'));
      expect(counter.map, isNotEmpty);
      expect(counter.totalCount, equals(6)); // 1 + 2 + 3
      expect(counter.getCountOf('bucket-0'), equals(0));
      expect(counter.getCountOf('bucket-1'), equals(1));
      expect(counter.getCountOf('bucket-2'), equals(2));
      expect(counter.getCountOf('bucket-3'), equals(3));
    });
  });

  group('MeanReciprocalRankComputer', () {
    test('empty', () {
      var mrrc = MeanReciprocalRankComputer();
      expect(mrrc.rankCount, equals(0));
      expect(mrrc.ranks, isEmpty);
      expect(mrrc.getMRR(), equals(0));
    });

    test('clear', () {
      var mrrc = MeanReciprocalRankComputer();
      mrrc.addRank(2);
      expect(mrrc.rankCount, equals(1));
      expect(mrrc.ranks, isNotEmpty);

      mrrc.clear();
      expect(mrrc.rankCount, equals(0));
      expect(mrrc.ranks, isEmpty);
    });

    test('mmr- single value', () {
      var mrrc = MeanReciprocalRankComputer();
      mrrc.addRank(3);
      mrrc.addRank(3);
      mrrc.addRank(3);
      mrrc.addRank(3);
      mrrc.addRank(3);
      expect(mrrc.rankCount, equals(5));
      expect(mrrc.ranks, equals([3, 3, 3, 3, 3]));
      expect(mrrc.getMRR(), doubleEquals(1 / 3));
    });

    test('mmr- example', () {
      var mrrc = MeanReciprocalRankComputer();
      mrrc.addRank(3);
      mrrc.addRank(2);
      mrrc.addRank(1);
      expect(mrrc.rankCount, equals(3));
      expect(mrrc.ranks, equals([3, 2, 1]));
      expect(mrrc.getMRR(), doubleEquals(11 / 18));
    });

    test('mmr- max rank', () {
      var mrrc = MeanReciprocalRankComputer();
      mrrc.addRank(3);
      mrrc.addRank(2);
      mrrc.addRank(1);
      expect(mrrc.rankCount, equals(3));
      expect(mrrc.ranks, equals([3, 2, 1]));
      expect(mrrc.getMRR(2), doubleEquals(1 / 2));
    });
  });

  group('Place', () {
    test('none', () {
      var place = Place.none();
      expect(place.numerator, equals(0));
      expect(place.denominator, equals(0));
      expect(place.rank, equals(0));
      expect(place, equals(Place.none()));
      expect(place == Place(1, 1), isFalse);
    });

    test('default', () {
      var place = Place(10, 20);
      expect(place.numerator, equals(10));
      expect(place.rank, equals(10));
      expect(place.denominator, equals(20));
      expect(place, equals(Place(10, 20)));
      expect(place == Place(1, 2), isFalse);
      expect(place == Place(10, 200), isFalse);
      expect(place == Place(1, 20), isFalse);
    });
  });
}

/// Returns matcher that can compare double values.
Matcher doubleEquals(expected) => _DoubleEquals(expected);

class _DoubleEquals extends Matcher {
  final double _value;
  final int fractionDigits = 10;

  const _DoubleEquals(this._value);

  @override
  Description describe(Description description) =>
      description.add(_value.toString());

  @override
  bool matches(item, Map matchState) {
    return item is num &&
        item != null &&
        _value != null &&
        num.parse(item.toStringAsFixed(fractionDigits)) ==
            num.parse(_value.toStringAsFixed(fractionDigits));
  }
}
