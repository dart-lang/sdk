// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for downcasts on native classes.

import "native_testing.dart";

abstract class J {}

abstract class I extends J {
  I read();
  write(I x);
}

// Native implementation.

@Native("A")
class A implements I {
  // The native class accepts only other native instances.
  A read() native;
  write(A x) native;
}

@Native("B")
class B extends A {}

makeA() native;
makeB() native;

void setup() native """
// This code is all inside 'setup' and so not accessible from the global scope.
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
A.prototype.read = function() { return this._x; };
A.prototype.write = function(x) { this._x = x; };
makeA = function(){return new A};
makeB = function(){return new B};

self.nativeConstructor(A);
self.nativeConstructor(B);
""";

class C {}

bool _check(a, b) => identical(a, b);

main() {
  nativeTesting();
  setup();

  var a1 = makeA();
  var b1 = makeB();
  var ob = new Object();

  Expect.throws(() => ob as J);
  Expect.throws(() => ob as I);
  Expect.throws(() => ob as A);
  Expect.throws(() => ob as B);
  Expect.throws(() => ob as C);

  // Use b1 first to prevent a1 is checks patching the A prototype.
  Expect.equals(b1, b1 as J);
  Expect.equals(b1, b1 as I);
  Expect.equals(b1, b1 as A);
  Expect.equals(b1, b1 as B);

  Expect.equals(a1, a1 as J);
  Expect.equals(a1, a1 as I);
  Expect.equals(a1, a1 as A);
  Expect.throws(() => a1 as B);
  Expect.throws(() => a1 as C);
}
