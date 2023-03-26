// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(51557): Decide if the mixins being applied in this test should be
// "mixin", "mixin class" or the test should be left at 2.19.
// @dart=2.19

import "package:expect/expect.dart";

class M1 = Object with M0;
class M2 = Object with M1;

class M0 {
  foo() => 42;
}

makeM2() {
  return [new Object(), new M2()].last as M2;
}

main() {
  Expect.equals(42, makeM2().foo());
}
