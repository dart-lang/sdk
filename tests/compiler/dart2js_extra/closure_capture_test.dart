// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

closure0() {
  var x = 499;
  var f = () { return x; };
  Expect.equals(499, f());
}

class A {
  closure1() {
    var x = 499;
    var f = () { return x; };
    Expect.equals(499, f());
  }
}

applyFun(f) {
  return f();
}

closure2() {
  var x = 499;
  Expect.equals(499, applyFun(() { return x; }));
}

closure3() {
  var y = 400;
  var f = (x) { return y + x; };
  Expect.equals(499, f(99));
}

applyFun2(f) {
  return f(400, 90);
}

closure4() {
  var z = 9;
  Expect.equals(499, applyFun2((x, y) { return x + y + z; }));
}

closure5() {
  var x = 498;
  var f = () { return x; };
  x++;
  Expect.equals(499, f());
}

class A2 {
  closure6() {
    var x = 498;
    var f = () { return x; };
    x++;
    Expect.equals(499, f());
  }
}

closure7() {
  var x = 498;
  var f = () { return x; };
  x++;
  Expect.equals(499, applyFun(f));
}

closure8() {
  var y = 399;
  var f = (x) { return y + x; };
  y++;
  Expect.equals(499, f(99));
}

closure9() {
  var z = 9;
  Expect.equals(499, applyFun2((x, y) { return x + y + z; }));
}

main() {
  closure0();
  new A().closure1();
  closure2();
  closure3();
  closure4();
  closure5();
  new A2().closure6();
  closure7();
  closure8();
  closure9();
}
