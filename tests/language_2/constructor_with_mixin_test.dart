// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test super constructor invocation with mixins.
// Regression test for issue dartbug.com/22604

import "package:expect/expect.dart";

var a_count = 0;
var b_count = 0;

class A {
  final int x;
  A(int this.x) {
    a_count++;
  }
}

class I {}

class B extends A with I {
  int y;

  B(int xx)
      : y = 13,
        super(xx) {
    b_count++;
  }
}

void main() {
  var b = new B(17);
  Expect.equals(1, a_count);
  Expect.equals(1, b_count);
}
