// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "native_testing.dart";

// Test that native classes can use ordinary Dart classes as mixins.

@Native("A")
class A {
  foo() => "A-foo";
  baz() => "A-baz";
}

@Native("B")
class B extends A with M {
  bar() => baz();
}

class M {
  foo() => "M-foo";
  bar() => "M-bar";
}

A makeA() native;
B makeB() native;

void setup() native """
function A() {}
function B() {}
makeA = function(){return new A;};
makeB = function(){return new B;};

self.nativeConstructor(A);
self.nativeConstructor(B);
""";

main() {
  nativeTesting();
  setup();
  A a = makeA();
  Expect.equals("A-foo", a.foo());
  Expect.throws(() => a.bar(), (error) => error is NoSuchMethodError);
  Expect.equals("A-baz", a.baz());
  Expect.isTrue(a is A);
  Expect.isFalse(a is B);
  Expect.isFalse(a is M);

  B b = makeB();
  Expect.equals("M-foo", b.foo());
  Expect.equals("A-baz", b.bar());
  Expect.equals("A-baz", b.baz());
  Expect.isTrue(b is A);
  Expect.isTrue(b is B);
  Expect.isTrue(b is M);

  M m = new M();
  Expect.equals("M-foo", m.foo());
  Expect.equals("M-bar", m.bar());
  Expect.throws(() => m.baz(), (error) => error is NoSuchMethodError);
  Expect.isFalse(m is A);
  Expect.isFalse(m is B);
  Expect.isTrue(m is M);
}
