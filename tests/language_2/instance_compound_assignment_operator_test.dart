// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test correct instance compound assignment operator.

import "package:expect/expect.dart";

class A {
  A() : f = 2 {}
  var f;
  operator [](index) => f;
  operator []=(index, value) => f = value;

  var _g = 0;
  var gGetCount = 0;
  var gSetCount = 0;
  get g {
    gGetCount++;
    return _g;
  }

  set g(value) {
    gSetCount++;
    _g = value;
  }
}

class B {
  B()
      : _a = new A(),
        count = 0 {}
  get a {
    count++;
    return _a;
  }

  var _a;
  var count;
}

var globalA;
var fooCounter = 0;
foo() {
  fooCounter++;
  return globalA;
}

main() {
  B b = new B();
  Expect.equals(0, b.count);
  Expect.equals(2, b.a.f);
  Expect.equals(1, b.count);
  var o = b.a;
  Expect.equals(2, b.count);
  b.a.f = 1;
  Expect.equals(3, b.count);
  Expect.equals(1, b._a.f);
  b.a.f += 1;
  Expect.equals(4, b.count);
  Expect.equals(2, b._a.f);

  b.count = 0;
  b._a.f = 2;
  Expect.equals(0, b.count);
  Expect.equals(2, b.a[0]);
  Expect.equals(1, b.count);
  o = b.a;
  Expect.equals(2, b.count);
  b.a[0] = 1;
  Expect.equals(3, b.count);
  Expect.equals(1, b._a.f);
  b.a[0] += 1;
  Expect.equals(4, b.count);
  Expect.equals(2, b._a.f);

  b._a.g++;
  Expect.equals(1, b._a.gGetCount);
  Expect.equals(1, b._a.gSetCount);
  Expect.equals(1, b._a._g);

  globalA = b._a;
  globalA.f = 0;
  foo().f += 1;
  Expect.equals(1, fooCounter);
  Expect.equals(1, globalA.f);
}
