// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "native_testing.dart";

// Additional Dart code may be 'placed on' hidden native classes.  With
// inheritance, the superclass method must not be reached by a call on the
// subclass.

@Native("A")
class A {
  var _field;

  int get X => _field;
  void set X(int x) {
    _field = x;
  }

  int method(int z) => _field + z;
}

@Native("B")
class B extends A {
  var _field2;

  int get X => _field2;
  void set X(int x) {
    _field2 = x;
  }

  int method(int z) => _field2 + z;
}

A makeA() native;
B makeB() native;

void setup() native r"""
function inherits(child, parent) {
  if (child.prototype.__proto__) {
    child.prototype.__proto__ = parent.prototype;
  } else {
    function tmp() {};
    tmp.prototype = parent.prototype;
    child.prototype = new tmp();
    child.prototype.constructor = child;
  }
}

function A(){}
function B(){}
inherits(B, A);
makeA = function(){return new A;};
makeB = function(){return new B;};

self.nativeConstructor(A);
self.nativeConstructor(B);
""";

testBasicA_dynamic() {
  setup(); // Fresh constructors.

  var a = [makeA()][0];

  a.X = 100;
  Expect.equals(100, a._field);
  Expect.equals(100, a.X);
  Expect.equals(150, a.method(50));
}

testBasicA_typed() {
  setup(); // Fresh constructors.

  A a = makeA();

  a.X = 100;
  Expect.equals(100, a._field);
  Expect.equals(100, a.X);
  Expect.equals(150, a.method(50));
}

testBasicB_dynamic() {
  setup(); // Fresh constructors.

  var b = [makeB()][0];

  b._field = 1;
  b.X = 123;
  Expect.equals(1, b._field);
  Expect.equals(123, b._field2);
  Expect.equals(123, b.X);
  Expect.equals(200, b.method(77));
}

testBasicB_typed() {
  setup(); // Fresh constructors.

  B b = makeB();

  b._field = 1;
  b.X = 123;
  Expect.equals(1, b._field);
  Expect.equals(123, b._field2);
  Expect.equals(123, b.X);
  Expect.equals(200, b.method(77));
}

testAB_dynamic() {
  setup(); // Fresh constructors.

  var things = [makeA(), makeB()];
  var a = things[0];
  var b = things[1];

  a.X = 100;
  Expect.equals(100, a._field);
  Expect.equals(100, a.X);
  Expect.equals(150, a.method(50));

  b._field = 1;
  b._field2 = 2;
  b.X = 123;
  Expect.equals(1, b._field);
  Expect.equals(123, b._field2);
  Expect.equals(123, b.X);
  Expect.equals(200, b.method(77));
}

testAB_typed() {
  setup(); // Fresh constructors.

  A a = makeA();
  B b = makeB();

  a.X = 100;
  Expect.equals(100, a._field);
  Expect.equals(100, a.X);
  Expect.equals(150, a.method(50));

  b._field = 1;
  b._field2 = 2;
  b.X = 123;
  Expect.equals(1, b._field);
  Expect.equals(123, b._field2);
  Expect.equals(123, b.X);
  Expect.equals(200, b.method(77));
}

main() {
  nativeTesting();
  testBasicA_dynamic();
  testBasicA_typed();
  testBasicB_dynamic();
  testBasicB_typed();
  testAB_dynamic();
  testAB_typed();
}
