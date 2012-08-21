// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test similar to NativeCallArity1FrogTest, but with default values to
// parameters set to null. These parameters should be treated as if they
// do not have a default value for the native methods.

@native("*A")
class A  {
  @native int foo(int x);
}

@native("*B")
class B  {
  @native int foo([x = null, y, z = null]);
}

// TODO(sra): Add a case where the parameters have default values.  Wait until
// dart:dom_deprecated / dart:html need non-null default values.

@native A makeA() { return new A(); }
@native B makeB() { return new B(); }

@native("""
function A() {}
A.prototype.foo = function () { return arguments.length; };

function B() {}
B.prototype.foo = function () { return arguments.length; };

makeA = function(){return new A;};
makeB = function(){return new B;};
""")
void setup();


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

  Expect.equals(1, b.foo(x: 10));   // 1 = x
  Expect.equals(2, b.foo(y: 20));   // 2 = x, y
  Expect.equals(3, b.foo(z: 30));   // 3 = x, y, z
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

  Expect.equals(1, b.foo(x: 10));
  Expect.equals(2, b.foo(y: 20));
  Expect.equals(3, b.foo(z: 30));
  Expect.throws(() => b.foo(10, 20, 30, 40));
}

main() {
  setup();
  testDynamicContext();
  testStaticContext();
}
