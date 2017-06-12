// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  foo() {}
  bar() {}
}

class B {
  var x;
  final y;

  B(a)
      : x = a
          ..foo()
          ..bar(),
        y = a
          ..foo()
          ..bar() {}
}

main() {
  var a = new A(), b = new B(a);
  Expect.equals(a, b.x);
  Expect.equals(a, b.y);
}
