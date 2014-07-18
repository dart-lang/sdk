// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_js_helper";
import "package:expect/expect.dart";

// Test for correct simple is-checks on hidden native classes.

abstract class J {
}

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
class B extends A {
}

makeA() native;
makeB() native;

void setup() native """
// This code is all inside 'setup' and so not accesible from the global scope.
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
""";

class C {}

main() {
  setup();

  var a1 = makeA();
  var b1 = makeB();
  var ob = new Object();

  Expect.isFalse(ob is J);
  Expect.isFalse(ob is I);
  Expect.isFalse(ob is A);
  Expect.isFalse(ob is B);
  Expect.isFalse(ob is C);

  // Use b1 first to prevent a1 is checks patching the A prototype.
  Expect.isTrue(b1 is J);
  Expect.isTrue(b1 is I);
  Expect.isTrue(b1 is A);
  Expect.isTrue(b1 is B);
  Expect.isTrue(b1 is !C);

  Expect.isTrue(a1 is J);
  Expect.isTrue(a1 is I);
  Expect.isTrue(a1 is A);
  Expect.isTrue(a1 is !B);
  Expect.isTrue(a1 is !C);
}
