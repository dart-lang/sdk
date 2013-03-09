// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that native methods with unnamed* optional arguments are called with the
// number of arguments in the call site.  This is necessary because native
// methods can dispatch on the number of arguments.  Passing null or undefined
// as the last argument is not the same as passing one fewer argument.
//
// * Named arguments are passed in the correct position, so require preceding
// arguments to be passed.

import 'native_metadata.dart';

@Native("*A")
class A {
  @native int foo(int x);
}

@Native("*B")
class B {
  @native int foo([x, y, z]);
}

// TODO(sra): Add a case where the parameters have default values.  Wait until
// dart:html need non-null default values.

@native A makeA() { return new A(); }
@native B makeB() { return new B(); }

@Native("""
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
