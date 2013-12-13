// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.multiset_test;

import 'package:barback/src/multiset.dart';
import 'package:unittest/unittest.dart';

import 'utils.dart';

main() {
  initConfig();

  test("new Multiset() creates an empty set", () {
    var multiSet = new Multiset();
    expect(multiSet, isEmpty);
    expect(multiSet.contains(1), isFalse);
    expect(multiSet.count(1), equals(0));
  });

  test("new Multiset.from(...) constructs a set from the argument", () {
    var multiSet = new Multiset.from([1, 2, 3, 2, 4]);
    expect(multiSet.toList(), equals([1, 2, 2, 3, 4]));
    expect(multiSet.contains(1), isTrue);
    expect(multiSet.contains(5), isFalse);
    expect(multiSet.count(1), equals(1));
    expect(multiSet.count(2), equals(2));
    expect(multiSet.count(5), equals(0));
  });

  test("an element can be added and removed once", () {
    var multiSet = new Multiset();
    expect(multiSet.contains(1), isFalse);
    multiSet.add(1);
    expect(multiSet.contains(1), isTrue);
    multiSet.remove(1);
    expect(multiSet.contains(1), isFalse);
  });

  test("a set can contain multiple copies of an element", () {
    var multiSet = new Multiset();
    expect(multiSet.count(1), equals(0));
    multiSet.add(1);
    expect(multiSet.count(1), equals(1));
    multiSet.add(1);
    expect(multiSet.count(1), equals(2));
    multiSet.remove(1);
    expect(multiSet.count(1), equals(1));
    multiSet.remove(1);
    expect(multiSet.count(1), equals(0));
  });

  test("remove returns false if the element wasn't in the set", () {
    var multiSet = new Multiset();
    expect(multiSet.remove(1), isFalse);
  });

  test("remove returns true if the element was in the set", () {
    var multiSet = new Multiset.from([1]);
    expect(multiSet.remove(1), isTrue);
  });

  test("remove returns true if the element was in the set even if more copies "
      "remain", () {
    var multiSet = new Multiset.from([1, 1, 1]);
    expect(multiSet.remove(1), isTrue);
  });

  test("iterator orders distinct elements in insertion order", () {
    var multiSet = new Multiset()..add(1)..add(2)..add(3)..add(4)..add(5);
    expect(multiSet.toList(), equals([1, 2, 3, 4, 5]));
  });

  test("iterator groups multiple copies of an element together", () {
    var multiSet = new Multiset()..add(1)..add(2)..add(1)..add(2)..add(1);
    expect(multiSet.toList(), equals([1, 1, 1, 2, 2]));
  });
}
