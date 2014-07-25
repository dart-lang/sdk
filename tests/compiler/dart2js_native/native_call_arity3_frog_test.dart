// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_js_helper";
import "package:expect/expect.dart";

// Test similar to NativeCallArity1FrogTest, but with default values to
// parameters set to null. These parameters should be treated as if they
// do not have a default value for the native methods.

@Native("A")
class A {
  int foo(int x) native;
}

@Native("B")
class B {
  int foo([x = null, y, z = null]) native;
}

// TODO(sra): Add a case where the parameters have default values.  Wait until
// dart:html need non-null default values.

A makeA() native;
B makeB() native;

void setup() native """
function A() {}
A.prototype.foo = function () { return arguments.length; };

function B() {}
B.prototype.foo = function () { return arguments.length; };

makeA = function(){return new A;};
makeB = function(){return new B;};
""";


testDynamicContext() {
  var things = [makeA(), makeB()];
  var a = things[0];
  var b = things[1];

  Expect.throws(() => a.foo());
  Expect.equals(1, a.foo(10));
  Expect.throws(() => a.foo(10, 20));
  Expect.throws(() => a.foo(10, 20, 30));

  Expect.equals(0, b.foo());
  Expect.equals(1, b.foo(10));
  Expect.equals(2, b.foo(10, 20));
  Expect.equals(3, b.foo(10, 20, 30));

  Expect.equals(1, b.foo(10));
  Expect.equals(2, b.foo(null, 20));
  Expect.equals(3, b.foo(null, null, 30));
  Expect.throws(() => b.foo(10, 20, 30, 40));
}

testStaticContext() {
  A a = makeA();
  B b = makeB();

  Expect.throws(() => a.foo());
  Expect.equals(1, a.foo(10));
  Expect.throws(() => a.foo(10, 20));
  Expect.throws(() => a.foo(10, 20, 30));

  Expect.equals(0, b.foo());
  Expect.equals(1, b.foo(10));
  Expect.equals(2, b.foo(10, 20));
  Expect.equals(3, b.foo(10, 20, 30));

  Expect.equals(1, b.foo(10));
  Expect.equals(2, b.foo(null, 20));
  Expect.equals(3, b.foo(null, null, 30));
  Expect.throws(() => b.foo(10, 20, 30, 40));
}

main() {
  setup();
  testDynamicContext();
  testStaticContext();
}
