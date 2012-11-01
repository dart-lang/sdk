// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test for Splaytrees.
#library("SplayTreeTest.dart");
#import("dart:collection");


class SplayTreeMapTest {

  static testMain() {
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
  }
}

main() {
  SplayTreeMapTest.testMain();
}
