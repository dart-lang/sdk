// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test for Splaytrees.
library splay_tree_test;

import "package:expect/expect.dart";
import 'dart:collection';

main() {
  // Simple tests.
  SplayTreeMap tree = new SplayTreeMap();
  tree[1] = "first";
  tree[3] = "third";
  tree[5] = "fifth";
  tree[2] = "second";
  tree[4] = "fourth";

  var correctSolution = ["first", "second", "third", "fourth", "fifth"];

  tree.forEach((key, value) {
    Expect.equals(true, key >= 1);
    Expect.equals(true, key <= 5);
    Expect.equals(value, correctSolution[key - 1]);
  });

  for (var v in ["first", "second", "third", "fourth", "fifth"]) {
    Expect.isTrue(tree.containsValue(v));
  }
  ;
  Expect.isFalse(tree.containsValue("sixth"));

  tree[7] = "seventh";

  Expect.equals(1, tree.firstKey());
  Expect.equals(7, tree.lastKey());

  Expect.equals(2, tree.lastKeyBefore(3));
  Expect.equals(4, tree.firstKeyAfter(3));

  Expect.equals(null, tree.lastKeyBefore(1));
  Expect.equals(2, tree.firstKeyAfter(1));

  Expect.equals(4, tree.lastKeyBefore(5));
  Expect.equals(7, tree.firstKeyAfter(5));

  Expect.equals(5, tree.lastKeyBefore(7));
  Expect.equals(null, tree.firstKeyAfter(7));

  Expect.equals(5, tree.lastKeyBefore(6));
  Expect.equals(7, tree.firstKeyAfter(6));

  testSetFrom();
  regressRemoveWhere();
  regressRemoveWhere2();
  regressFromCompare();
}

void regressRemoveWhere() {
  // Regression test. Fix in https://codereview.chromium.org/148523006/
  var t = new SplayTreeSet();
  t.addAll([1, 3, 5, 7, 2, 4, 6, 8, 0]);
  var seen = new List<bool>.filled(9, false);
  t.removeWhere((x) {
    // Called only once per element.
    Expect.isFalse(seen[x], "seen $x");
    seen[x] = true;
    return x.isOdd;
  });
}

void regressRemoveWhere2() {
  // Regression test for http://dartbug.com/18676
  // Removing all elements with removeWhere causes error.

  var t = new SplayTreeSet();
  t.addAll([1, 2, 3, 4, 5]);
  t.removeWhere((_) => true); // Should not throw.
  Expect.isTrue(t.isEmpty);
  t.addAll([1, 2, 3, 4, 5]);
  t.retainWhere((_) => false); // Should not throw.
  Expect.isTrue(t.isEmpty);
}

void testSetFrom() {
  var set1 = new SplayTreeSet<num>()..addAll([1, 2, 3, 4, 5]);
  var set2 = new SplayTreeSet<int>.from(set1);
  Expect.equals(5, set2.length);
  for (int i = 1; i <= 5; i++) {
    Expect.isTrue(set2.contains(i));
  }

  set1 = new SplayTreeSet<num>()..addAll([0, 1, 2.4, 3.14, 5]);
  set2 = new SplayTreeSet<int>.from(set1.where((x) => x is int));
  Expect.equals(3, set2.length);
}

void regressFromCompare() {
  // Regression test for http://dartbug.com/23387.
  // The compare and isValidKey arguments to SplayTreeMap.from were ignored.

  int compare(a, b) {
    if (a is IncomparableKey && b is IncomparableKey) {
      return b.id - a.id;
    }
    throw "isValidKey failure";
  }

  bool isValidKey(o) => o is IncomparableKey;
  IncomparableKey key(int n) => new IncomparableKey(n);

  var entries = {key(0): 0, key(1): 1, key(2): 2, key(0): 0};
  Expect.equals(4, entries.length);
  var map =
      new SplayTreeMap<IncomparableKey, int>.from(entries, compare, isValidKey);
  Expect.equals(3, map.length);
  for (int i = 0; i < 3; i++) {
    Expect.isTrue(map.containsKey(key(i)));
    Expect.equals(i, map[key(i)]);
  }
  Expect.isFalse(map.containsKey(key(5)));
  Expect.isFalse(map.containsKey(1));
  Expect.isFalse(map.containsKey("string"));
  Expect.equals(null, map[key(5)]);
  Expect.equals(null, map[1]);
  Expect.equals(null, map["string"]);
  map[1] = 42; //# 01: compile-time error
  map["string"] = 42; //# 02: compile-time error
  map[key(5)] = 42;
  Expect.equals(4, map.length);
  Expect.equals(42, map[key(5)]);
}

class IncomparableKey {
  final int id;
  IncomparableKey(this.id);
}
