// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10

import "package:expect/expect.dart";

// Test correct dead phi elimination with try catch.

List<Object> a = [1, 2, 3, 4, 5];

class MyError {}

class M {
  maythrow(i) {
    try {
      if (i <= 5) throw new MyError();
    } catch (e) {
      throw e;
    }
  }
}

loop_test() {
  bool failed = false;
  M m = new M();
  for (Object i in a) {
    try {
      String res = m.maythrow(i);
      failed = true;
    } on MyError catch (e) {}
    if (!identical(failed, false)) {
      Expect.fail("");
    }
  }
}

main() {
  for (var i = 0; i < 20; i++) loop_test();
}
