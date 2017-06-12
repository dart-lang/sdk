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
class B extends A with M1, M2 {
  bar() => baz();
}

class M1 {
  foo() => "M1-foo";
  baz() => "M1-baz";
}

class M2 {
  foo() => "M2-foo";
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
  Expect.isFalse(a is M1);
  Expect.isFalse(a is M2);

  B b = makeB();
  Expect.equals("M2-foo", b.foo());
  Expect.equals("M1-baz", b.bar());
  Expect.equals("M1-baz", b.baz());
  Expect.isTrue(b is A);
  Expect.isTrue(b is B);
  Expect.isTrue(b is M1);
  Expect.isTrue(b is M2);

  M1 m1 = new M1();
  Expect.equals("M1-foo", m1.foo());
  Expect.throws(() => m1.bar(), (error) => error is NoSuchMethodError);
  Expect.equals("M1-baz", m1.baz());
  Expect.isFalse(m1 is A);
  Expect.isFalse(m1 is B);
  Expect.isTrue(m1 is M1);
  Expect.isFalse(m1 is M2);

  M2 m2 = new M2();
  Expect.equals("M2-foo", m2.foo());
  Expect.throws(() => m2.bar(), (error) => error is NoSuchMethodError);
  Expect.throws(() => m2.baz(), (error) => error is NoSuchMethodError);
  Expect.isFalse(m2 is A);
  Expect.isFalse(m2 is B);
  Expect.isFalse(m2 is M1);
  Expect.isTrue(m2 is M2);
}
