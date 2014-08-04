// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

closure0() {
  var fib;
  fib = (i) {
    if (i < 2) return i;
    return fib(i - 1) + fib(i - 2);
  };
  Expect.equals(5, fib(5));
}

closure1() {
  var decr1 = 0;
  var decr2 = 0;
  var fib;
  fib = (i) {
    if (i < 2) return i;
    return fib(i - decr1) + fib(i - decr2);
  };
  decr1++;
  decr2 += 2;
  Expect.equals(5, fib(5));
}

closure2() {
  var f;
  f = (doReturnClosure) {
    if (doReturnClosure) {
      return () => f(false);
    } else {
      return 499;
    }
  };
  var g = f(true);
  Expect.equals(499, g());
}

main() {
  closure0();
  closure1();
  closure2();
}
