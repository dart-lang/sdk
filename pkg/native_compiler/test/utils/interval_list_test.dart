// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:native_compiler/utils/interval_list.dart';
import 'package:test/test.dart';

IntervalList createList(List<(int, int)> intervals) {
  final list = IntervalList();
  for (final interval in intervals.reversed) {
    list.addInterval(interval.$1, interval.$2);
  }
  return list;
}

void expectList(IntervalList actual, List<(int, int)> expected) {
  expect(actual.length, equals(expected.length));
  for (var i = 0; i < actual.length; ++i) {
    expect(actual.startAt(i), equals(expected[i].$1));
    expect(actual.endAt(i), equals(expected[i].$2));
  }
}

void main() {
  test('isEmpty', () {
    expect(IntervalList().isEmpty, isTrue);
    expect(createList([(10, 20)]).isEmpty, isFalse);
    expect(createList([(10, 20), (30, 40), (50, 60)]).isEmpty, isFalse);
  });

  test('addInterval', () {
    expectList(createList([(10, 20)]), [(10, 20)]);
    expectList(createList([(10, 20), (30, 40), (50, 60)]), [
      (10, 20),
      (30, 40),
      (50, 60),
    ]);

    // Merging intervals.
    expectList(createList([(10, 20), (20, 30)]), [(10, 30)]);
    expectList(createList([(10, 20), (30, 40), (40, 50), (50, 60), (70, 80)]), [
      (10, 20),
      (30, 60),
      (70, 80),
    ]);

    // Nested intervals.
    expectList(createList([(10, 20), (10, 30)]), [(10, 30)]);
    expectList(createList([(10, 20), (30, 40), (30, 50), (30, 60)]), [
      (10, 20),
      (30, 60),
    ]);

    // Both merging and nesting.
    expectList(createList([(10, 20), (20, 30), (20, 40), (40, 50)]), [
      (10, 50),
    ]);
  });

  test('intersects and firstIntersection', () {
    expect(createList([(10, 20)]).intersects(createList([(30, 40)])), isFalse);
    expect(
      createList([(10, 20)]).firstIntersection(0, createList([(30, 40)]), 0),
      equals(-1),
    );

    expect(
      createList([(10, 20), (30, 40)]).intersects(createList([(20, 30)])),
      isFalse,
    );
    expect(
      createList([
        (10, 20),
        (30, 40),
      ]).firstIntersection(0, createList([(20, 30)]), 0),
      equals(-1),
    );

    expect(
      createList([(10, 20), (30, 40)]).intersects(createList([(5, 45)])),
      isTrue,
    );
    expect(
      createList([
        (10, 20),
        (30, 40),
      ]).firstIntersection(0, createList([(5, 45)]), 0),
      equals(10),
    );
    expect(
      createList([
        (10, 20),
        (30, 40),
      ]).firstIntersection(1, createList([(5, 45)]), 0),
      equals(30),
    );

    expect(
      createList([(10, 20), (30, 40)]).intersects(createList([(35, 36)])),
      isTrue,
    );
    expect(
      createList([
        (10, 20),
        (30, 40),
      ]).firstIntersection(0, createList([(35, 36)]), 0),
      equals(35),
    );

    expect(
      createList([(10, 20), (30, 40)]).intersects(createList([(15, 35)])),
      isTrue,
    );
    expect(
      createList([
        (10, 20),
        (30, 40),
      ]).firstIntersection(0, createList([(15, 35)]), 0),
      equals(15),
    );
    expect(
      createList([
        (10, 20),
        (30, 40),
      ]).firstIntersection(1, createList([(15, 35)]), 0),
      equals(30),
    );

    expect(
      createList([
        (10, 20),
        (30, 40),
      ]).intersects(createList([(21, 22), (25, 26), (39, 41)])),
      isTrue,
    );
    expect(
      createList([
        (10, 20),
        (30, 40),
      ]).firstIntersection(0, createList([(21, 22), (25, 26), (39, 41)]), 0),
      equals(39),
    );
    expect(
      createList([
        (10, 20),
        (30, 40),
      ]).firstIntersection(0, createList([(21, 22), (25, 26), (39, 41)]), 1),
      equals(39),
    );
    expect(
      createList([
        (10, 20),
        (30, 40),
      ]).firstIntersection(1, createList([(21, 22), (25, 26), (39, 41)]), 2),
      equals(39),
    );
  });

  test('merge', () {
    final ilist = createList([(50, 60), (70, 80)]);
    ilist.merge(createList([]));
    expectList(ilist, [(50, 60), (70, 80)]);
    ilist.merge(createList([(90, 100)]));
    expectList(ilist, [(50, 60), (70, 80), (90, 100)]);
    ilist.merge(createList([(30, 40)]));
    expectList(ilist, [(30, 40), (50, 60), (70, 80), (90, 100)]);
    ilist.merge(createList([(10, 20), (65, 66)]));
    expectList(ilist, [
      (10, 20),
      (30, 40),
      (50, 60),
      (65, 66),
      (70, 80),
      (90, 100),
    ]);
    ilist.merge(createList([(40, 45)]));
    expectList(ilist, [
      (10, 20),
      (30, 45),
      (50, 60),
      (65, 66),
      (70, 80),
      (90, 100),
    ]);
    ilist.merge(createList([(25, 30), (45, 50)]));
    expectList(ilist, [(10, 20), (25, 60), (65, 66), (70, 80), (90, 100)]);
  });

  test('splitAt', () {
    final l1 = createList([(10, 20), (30, 40), (50, 60), (70, 80)]);
    final l2 = l1.splitAt(25);
    expectList(l1, [(10, 20)]);
    expectList(l2, [(30, 40), (50, 60), (70, 80)]);
    final l3 = l2.splitAt(55);
    expectList(l2, [(30, 40), (50, 55)]);
    expectList(l3, [(55, 60), (70, 80)]);
    final l4 = l3.splitAt(80);
    expectList(l3, [(55, 60), (70, 80)]);
    expectList(l4, []);
  });

  test('toString', () {
    expect(createList([]).toString(), equals(''));
    expect(createList([(10, 20)]).toString(), equals('[10, 20)'));
    expect(
      createList([(10, 20), (30, 40), (50, 60)]).toString(),
      equals('[10, 20), [30, 40), [50, 60)'),
    );
  });
}
