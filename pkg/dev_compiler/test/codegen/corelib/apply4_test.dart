// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Testing Function.apply calls work correctly for arities that are not
// otherwise present in the program (and thus might not have stubs
// generated).

class A {
  foo(x, [y, z, a, b, c, d = 99, e, f, g, h, i, j]) => "$x $d";
}

main() {
  var a = new A();
  var clos = a.foo;
  Expect.equals(Function.apply(clos, ["well"]), "well 99");
  Expect.equals(Function.apply(clos, ["well", 0, 2, 4, 3, 6, 9, 10]), "well 9");
}
