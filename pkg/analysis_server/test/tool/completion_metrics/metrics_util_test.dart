// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../../../tool/completion_metrics/metrics_util.dart';

void main() {
  group('ArithmeticMeanComputer', () {
    test('empty', () {
      var computer = ArithmeticMeanComputer('empty');
      expect(computer.sum, equals(0));
      expect(computer.count, equals(0));
    });

    test('clear', () {
      var computer = ArithmeticMeanComputer('name');
      computer.addValue(5);
      computer.addValue(5);
      computer.addValue(5);

      expect(computer.sum, equals(15));
      expect(computer.count, equals(3));
      computer.clear();

      expect(computer.sum, equals(0));
      expect(computer.count, equals(0));
    });

    test('mean', () {
      var computer = ArithmeticMeanComputer('name');
      computer.addValue(1);
      computer.addValue(2);
      computer.addValue(3);
      computer.addValue(4);
      computer.addValue(5);

      expect(computer.sum, equals(15));
      expect(computer.count, equals(5));
      expect(computer.mean, equals(15 / 5));
    });
  });

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
      var mrrc = MeanReciprocalRankComputer('');
      expect(mrrc.count, equals(0));
      expect(mrrc.mrr, equals(0));
    });

    test('clear', () {
      var mrrc = MeanReciprocalRankComputer('');
      mrrc.addRank(2);
      expect(mrrc.count, equals(1));
      expect(mrrc.mrr, equals(1 / 2));
      expect(mrrc.mrr_5, equals(1 / 2));

      mrrc.clear();
      expect(mrrc.count, equals(0));
      expect(mrrc.mrr, equals(0));
      expect(mrrc.mrr_5, equals(0));
    });

    test('mmr- single value', () {
      var mrrc = MeanReciprocalRankComputer('');
      mrrc.addRank(3);
      mrrc.addRank(3);
      mrrc.addRank(3);
      mrrc.addRank(3);
      mrrc.addRank(3);
      expect(mrrc.count, equals(5));
      expect(mrrc.mrr, doubleEquals(1 / 3));
      expect(mrrc.mrr_5, doubleEquals(1 / 3));
    });

    test('mmr- example', () {
      var mrrc = MeanReciprocalRankComputer('');
      mrrc.addRank(3);
      mrrc.addRank(2);
      mrrc.addRank(1);
      expect(mrrc.count, equals(3));
      expect(mrrc.mrr, doubleEquals(11 / 18));
      expect(mrrc.mrr_5, doubleEquals(11 / 18));
    });

    test('mmr- max rank', () {
      var mrrc = MeanReciprocalRankComputer('');
      mrrc.addRank(6);
      mrrc.addRank(5);
      mrrc.addRank(4);
      mrrc.addRank(3);
      mrrc.addRank(2);
      mrrc.addRank(1);
      expect(mrrc.count, equals(6));
      expect(mrrc.mrr, greaterThan(mrrc.mrr_5));
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
