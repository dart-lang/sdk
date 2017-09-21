// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test that ensures that fields can be accessed dynamically.

import "package:expect/expect.dart";

class C {
  final x = "hello";
  get y => ", ";
  m() => "world!";
}

// Regression test for https://github.com/dart-lang/sdk/issues/27258
main() {
  dynamic c = new C();
  Expect.equals(c.x + c.y + c.m(), "hello, world!");

  Expect.throws(() {
    c.x = 1;
  });
  Expect.throws(() {
    c.x = '1';
  });
  Expect.throws(() {
    c.y = '2';
  });
  Expect.throws(() {
    c.m = '3';
  });

  Expect.equals(c.x + c.y + c.m(), "hello, world!");
}
