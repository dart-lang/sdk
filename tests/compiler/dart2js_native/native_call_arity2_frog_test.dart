// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "native_testing.dart";

// This is a similar test to NativeCallArity1FrogTest, but makes sure
// that subclasses also get the right number of arguments.

@Native("A")
class A {
  int foo([x, y]) native;
}

@Native("B")
class B extends A {
  int foo([x, y]) native;
}

makeA() native;
makeB() native;

void setup() {
  JS('', r"""
(function(){
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
  function A() {}
  A.prototype.foo = function () { return arguments.length; };

  function B() {}
  B.prototype.foo = function () { return arguments.length; };
  inherits(B, A);

  makeA = function(){return new A()};
  makeB = function(){return new B()};

  self.nativeConstructor(A);
  self.nativeConstructor(B);
})()""");
}

testDynamicContext() {
  var a = confuse(makeA());
  var b = confuse(makeB());

  Expect.equals(0, a.foo());
  Expect.equals(1, a.foo(10));
  Expect.equals(2, a.foo(10, 20));
  Expect.throws(() => a.foo(10, 20, 30));

  Expect.equals(1, a.foo(10));
  Expect.equals(2, a.foo(null, 20));
  Expect.throws(() => a.foo(10, 20, 30));

  Expect.equals(0, b.foo());
  Expect.equals(1, b.foo(10));
  Expect.equals(2, b.foo(10, 20));
  Expect.throws(() => b.foo(10, 20, 30));

  Expect.equals(1, b.foo(10));
  Expect.equals(2, b.foo(null, 20));
  Expect.throws(() => b.foo(10, 20, 30));
}

testStaticContext() {
  A a = makeA();
  B b = makeB();

  Expect.equals(0, a.foo());
  Expect.equals(1, a.foo(10));
  Expect.equals(2, a.foo(10, 20));
  Expect.throws(() => a.foo(10, 20, 30));

  Expect.equals(1, a.foo(10));
  Expect.equals(2, a.foo(null, 20));
  Expect.throws(() => a.foo(10, 20, 30));

  Expect.equals(0, b.foo());
  Expect.equals(1, b.foo(10));
  Expect.equals(2, b.foo(10, 20));
  Expect.throws(() => b.foo(10, 20, 30));

  Expect.equals(1, b.foo(10));
  Expect.equals(2, b.foo(null, 20));
  Expect.throws(() => b.foo(10, 20, 30));
}

main() {
  nativeTesting();
  setup();
  testDynamicContext();
  testStaticContext();
}
