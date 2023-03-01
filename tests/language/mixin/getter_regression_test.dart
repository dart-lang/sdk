// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(51557): Decide if the mixins being applied in this test should be
// "mixin", "mixin class" or the test should be left at 2.19.
// @dart=2.19

// Regression test case for dart2js bug where the getter for y wasn't
// properly mixed in.

import "package:expect/expect.dart";

class C {
  int x = -1;
  int get y => x;
}

class E {
  int z = 10;
}

class D extends E with C {
  int w = 42;
}

main() {
  var d = new D();
  d.x = 37;
  Expect.equals(37, d.x);
  Expect.equals(10, d.z);
  Expect.equals(42, d.w);
  Expect.equals(37, d.y);
}
