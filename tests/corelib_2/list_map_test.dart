// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  testOperations();
}

class ThrowMarker {
  const ThrowMarker();
  String toString() => "<<THROWS>>";
}

void testOperations() {
  // Comparison lists.
  List l = const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  List r = const [10, 9, 8, 7, 6, 5, 4, 3, 2, 1];
  // Function that reverses l and r lists when used to map.
  int rev(x) => 11 - x;
  // A base list that starts out like l, but isn't const.
  List base = l.map((x) => x).toList();

  Iterable reversed = l.map(rev);

  Expect.listEquals(r, l.map(rev).toList());
  Expect.listEquals(l, l.map(rev).map(rev).toList());
  for (int i = 0; i < r.length; i++) {
    Expect.equals(r[i], reversed.elementAt(i));
  }
  Expect.equals(4, base.indexOf(5));
  Expect.equals(5, reversed.toList().indexOf(5));

  // Reversed followed by combinations of skip and take.
  List subr = [8, 7, 6, 5, 4, 3];
  Expect.listEquals(subr, reversed.skip(2).take(6).toList());
  Expect.listEquals(subr, reversed.take(8).skip(2).toList());
  Expect.listEquals(subr,
      reversed.toList().reversed.skip(2).take(6).toList().reversed.toList());
  Expect.listEquals(subr,
      reversed.toList().reversed.take(8).skip(2).toList().reversed.toList());
  Expect.listEquals(subr,
      reversed.take(8).toList().reversed.take(6).toList().reversed.toList());
  Expect.listEquals(subr,
      reversed.toList().reversed.take(8).toList().reversed.take(6).toList());
  Expect.listEquals(subr,
      reversed.toList().reversed.skip(2).toList().reversed.skip(2).toList());
  Expect.listEquals(subr,
      reversed.skip(2).toList().reversed.skip(2).toList().reversed.toList());

  void testList(List list) {
    var throws = const ThrowMarker();
    var mappedList = new List<int>(list.length);
    for (int i = 0; i < list.length; i++) {
      mappedList[i] = rev(list[i]);
    }
    Iterable<int> reversed = list.map(rev);

    void testEquals(v1, v2, path) {
      if (v1 is Iterable) {
        Iterator i1 = v1.iterator;
        Iterator i2 = v2.iterator;
        int index = 0;
        while (i1.moveNext()) {
          Expect.isTrue(i2.moveNext(),
              "Too few actual values. Expected[$index] == ${i1.current}");
          testEquals(i1.current, i2.current, "$path[$index]");
          index++;
        }
        if (i2.moveNext()) {
          Expect
              .fail("Too many actual values. Actual[$index] == ${i2.current}");
        }
      } else {
        Expect.equals(v1, v2, path);
      }
    }

    void testOp(operation(Iterable<int> mappedList), name) {
      var expect;
      try {
        expect = operation(mappedList);
      } catch (e) {
        expect = throws;
      }
      var actual;
      try {
        actual = operation(reversed);
      } catch (e) {
        actual = throws;
      }
      testEquals(expect, actual, "$name: $list");
    }

    testOp((i) => i.first, "first");
    testOp((i) => i.last, "last");
    testOp((i) => i.single, "single");
    testOp((i) => i.firstWhere((n) => false), "firstWhere<false");
    testOp((i) => i.firstWhere((n) => n < 10), "firstWhere<10");
    testOp((i) => i.firstWhere((n) => n < 5), "firstWhere<5");
    testOp((i) => i.firstWhere((n) => true), "firstWhere<true");
    testOp((i) => i.lastWhere((n) => false), "lastWhere<false");
    testOp((i) => i.lastWhere((n) => n < 5), "lastWhere<5");
    testOp((i) => i.lastWhere((n) => n < 10), "lastWhere<10");
    testOp((i) => i.lastWhere((n) => true), "lastWhere<true");
    testOp((i) => i.singleWhere((n) => false), "singleWhere<false");
    testOp((i) => i.singleWhere((n) => n < 5), "singelWhere<5");
    testOp((i) => i.singleWhere((n) => n < 10), "singelWhere<10");
    testOp((i) => i.singleWhere((n) => true), "singleWhere<true");
    testOp((i) => i.contains(5), "contains(5)");
    testOp((i) => i.contains(10), "contains(10)");
    testOp((i) => i.any((n) => n < 5), "any<5");
    testOp((i) => i.any((n) => n < 10), "any<10");
    testOp((i) => i.every((n) => n < 5), "every<5");
    testOp((i) => i.every((n) => n < 10), "every<10");
    testOp((i) => i.reduce((a, b) => a + b), "reduce-sum");
    testOp((i) => i.fold/*<int>*/(0, (a, b) => a + b), "fold-sum");
    testOp((i) => i.join("-"), "join-");
    testOp((i) => i.join(""), "join");
    testOp((i) => i.join(), "join-null");
    testOp((i) => i.map((n) => n * 2), "map*2");
    testOp((i) => i.where((n) => n < 5), "where<5");
    testOp((i) => i.where((n) => n < 10), "where<10");
    testOp((i) => i.expand((n) => []), "expand[]");
    testOp((i) => i.expand((n) => [n]), "expand[n]");
    testOp((i) => i.expand((n) => [n, n]), "expand[n, n]");
    testOp((i) => i.take(0), "take(0)");
    testOp((i) => i.take(5), "take(5)");
    testOp((i) => i.take(10), "take(10)");
    testOp((i) => i.take(15), "take(15)");
    testOp((i) => i.skip(0), "skip(0)");
    testOp((i) => i.skip(5), "skip(5)");
    testOp((i) => i.skip(10), "skip(10)");
    testOp((i) => i.skip(15), "skip(15)");
    testOp((i) => i.takeWhile((n) => false), "takeWhile(t)");
    testOp((i) => i.takeWhile((n) => n < 5), "takeWhile(n<5)");
    testOp((i) => i.takeWhile((n) => n > 5), "takeWhile(n>5)");
    testOp((i) => i.takeWhile((n) => true), "takeWhile(f)");
    testOp((i) => i.skipWhile((n) => false), "skipWhile(t)");
    testOp((i) => i.skipWhile((n) => n < 5), "skipWhile(n<5)");
    testOp((i) => i.skipWhile((n) => n > 5), "skipWhile(n>5)");
    testOp((i) => i.skipWhile((n) => true), "skipWhile(f)");
  }

  // Combinations of lists with 0, 1 and more elements.
  testList([]);
  testList([0]);
  testList([10]);
  testList([0, 1]);
  testList([0, 10]);
  testList([10, 11]);
  testList([0, 5, 10]);
  testList([10, 5, 0]);
  testList([0, 1, 2, 3]);
  testList([3, 4, 5, 6]);
  testList([10, 11, 12, 13]);
  testList(l);
  testList(r);
  testList(base);

  // Reverse const list.
  Expect.listEquals(r, l.map(rev).toList());
}
