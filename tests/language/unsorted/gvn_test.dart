// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  int x = 0;

  foo(i) {
    var start = x;
    do {
      x++;
      i++;
    } while (i != 10);
  }
}

main() {
  var a = new A();
  a.foo(0);
  Expect.equals(10, a.x);
}
