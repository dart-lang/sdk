// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test for Splaytrees.
#library("SplayTreeTest.dart");
#import("dart:coreimpl");


class SplayTreeTest {

  static testMain() {
    SplayTree tree = new SplayTree();
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
  }
}

main() {
  SplayTreeTest.testMain();
}
