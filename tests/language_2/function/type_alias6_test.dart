// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for legally self referencing function type alias.

import "package:expect/expect.dart";

typedef F(List<F> x);
// [error line 8, column 1, length 21]
// [analyzer] COMPILE_TIME_ERROR.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
//      ^
// [cfe] The typedef 'F' has a reference to itself.

typedef D C();

class D {
  C foo() {}
  D bar() {}
}

main() {
  var f = (List x) {};
  Expect.isTrue(f is F);
  var g = (List<F> x) {};
  Expect.isFalse(g is F);
  var d = new D();
  Expect.isTrue(d.foo is! C);
  Expect.isTrue(d.bar is C);
}
