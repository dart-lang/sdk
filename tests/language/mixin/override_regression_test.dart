// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(51557): Decide if the mixins being applied in this test should be
// "mixin", "mixin class" or the test should be left at 2.19.
// @dart=2.19

import "package:expect/expect.dart";

class C0 {
  int m1() => 5;
  int m2() => m1();
}

class C1 = Object with C0;

class D {
  int m1() => 7;
}

class E0 extends C0 with D {}

class E1 extends C1 with D {}

main() {
  Expect.equals(7, new E0().m2());
  Expect.equals(7, new E1().m2());
}
