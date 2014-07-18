// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_js_helper";
import "package:expect/expect.dart";

// Test that we put native names and not Dart names into the dynamic
// dispatch table.

@Native("NativeA")
class A {
  foo() native;
}

@Native("NativeB")
class B extends A {
}

A makeA() native { return new A(); }
B makeB() native { return new B(); }

void setup() native """
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
function NativeA() {}
function NativeB() {}
inherits(NativeB, NativeA);
NativeA.prototype.foo = function() { return 42; };

makeA = function(){return new NativeA;};
makeB = function(){return new NativeB;};
""";


main() {
  setup();

  var a = makeA();
  Expect.equals(42, a.foo());
  A aa = a;
  Expect.equals(42, aa.foo());

  var b = makeB();
  Expect.equals(42, b.foo());
  B bb = b;
  Expect.equals(42, bb.foo());
}
