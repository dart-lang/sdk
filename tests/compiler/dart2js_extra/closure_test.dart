// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

closure0() {
  // TODO(floitsch): remove name from functions.
  var f = fun() { return 499; };
  Expect.equals(499, f());
}

class A {
  closure1() {
    var f = fun() { return 499; };
    Expect.equals(499, f());
  }
}

applyFun(f) {
  return f();
}

closure2() {
  Expect.equals(499, applyFun(fun() { return 499; }));
}

closure3() {
  var f = fun(x) { return 400 + x; };
  Expect.equals(499, f(99));
}

applyFun2(f) {
  return f(400, 99);
}

closure4() {
  Expect.equals(499, applyFun2(fun(x, y) { return x + y; }));
}

main() {
  closure0();
  new A().closure1();
  closure2();
  closure3();
  closure4();
}
