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
  };
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
  t.removeWhere((_) => true);  // Should not throw.
  Expect.isTrue(t.isEmpty);
  t.addAll([1, 2, 3, 4, 5]);
  t.retainWhere((_) => false);  // Should not throw.
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
