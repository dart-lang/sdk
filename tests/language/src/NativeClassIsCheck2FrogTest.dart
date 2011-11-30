// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for correct is-checks on hidden native classes.

interface I {
  I read();
  write(I x);
}

// Native implementation.

class A implements I native "*A" {
  // The native class accepts only other native instances.
  A read() native;
  write(A x) native;
}

makeA() native;

void setup() native """
// This code is all inside 'setup' and so not accesible from the global scope.
function A(){}
A.prototype.read = function() { return this._x; };
A.prototype.write = function(x) { this._x = x; };
makeA = function(){return new A};
""";

// Dart implementation must coexist with native implementation.

class B implements I {
  B b;
  B read() { return b; }
  write(B x) { b = x; }
}

main() {
  setup();

  var a1 = makeA();
  var a2 = makeA();
  var b1 = new B();
  var b2 = new B();
  var ob = new Object();

  Expect.isFalse(ob is I);
  Expect.isFalse(ob is A);
  Expect.isFalse(ob is B);

  Expect.isTrue(b1 is I);
  Expect.isTrue(b1 is B);
  Expect.isFalse(b1 is A);

  Expect.isTrue(a1 is I);
  Expect.isTrue(a1 is A);
  Expect.isFalse(a1 is B);

  new TypeParameterTest<B>(b1, b2);
  new TypeParameterTest<I>(b1, b2);
  new TypeParameterTest<A>(a1, a2);
  new TypeParameterTest<I>(a1, a2);
}

class TypeParameterTest<T> {
  T _x;
  T _y;

  TypeParameterTest(x, y) {
    // In checked mode, the 'write' and 'read' operations will check arguments
    // and results.
    x.write(y);
    y.write(x);
    Expect.isTrue(x.read() === y);
    Expect.isTrue(y.read() === x);

    x.write(null);
    y.write(null);
    Expect.isTrue(x.read() === null);
    Expect.isTrue(y.read() === null);

    // Explicit checks against
    var ob = new Object();
    Expect.isTrue(ob is !T);
    Expect.isTrue(x is T);
    Expect.isTrue(y is T);

    // In checked mode, there is a parameterized type assertion in assignment.
    _x = x;
    _y = y;
  }
}
