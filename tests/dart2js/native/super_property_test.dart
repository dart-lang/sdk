// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "native_testing.dart";

// Tests super setter where the HInvokeSuper is using interceptor aka
// explicit-receiver calling convention.

@Native("A")
class A {
  var foo;
  get_foo() => foo;
  set bar(value) => foo = value;
}

@Native("B")
class B extends A {
  set foo(value) {
    super.foo = value;
  }

  get foo => super.foo;
}

class C {
  var foo;
  get_foo() => foo;
  set bar(value) => foo = value;
}

class D extends C {
  set foo(value) {
    super.foo = value;
  }

  get foo => super.foo;
}

makeA() native;
makeB() native;

void setup() {
  JS('', r"""
(function(){
  // This code is inside 'setup' and so not accessible from the global scope.
  function A(){}
  function B(){}
  makeA = function(){return new A()};
  makeB = function(){return new B()};
  self.nativeConstructor(A);
  self.nativeConstructor(B);
})()""");
}

testThing(a) {
  a.foo = 123;
  Expect.equals(123, a.foo);
  Expect.equals(123, a.get_foo());

  a.bar = 234;
  Expect.equals(234, a.foo);
  Expect.equals(234, a.get_foo());
}

main() {
  nativeTesting();
  setup();
  var things = [makeA(), makeB(), new C(), new D()];
  var test = testThing;
  test(things[0]);
  test(things[1]);
  test(things[2]);
  test(things[3]);
}
