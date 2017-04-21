// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "native_testing.dart";

// Test that native classes and plain classes can access methods defined only by
// the same mixin.

class D extends Object with M1, M2, M3 {}

class E extends D {
  foo() => 'E.foo';
}

class M1 {}

class M2 {
  foo() => 'M2.foo';
}

class M3 {}

@Native("A")
class A {
  foo() => 'A.foo';
}

@Native("B")
class B extends A with M1, M2, M3 {}

@Native("C")
class C extends B {
  foo() => 'C.foo';
}

makeA() native;
makeB() native;
makeC() native;

void setup() native """
function A() {}
function B() {}
function C() {}
makeA = function(){return new A;};
makeB = function(){return new B;};
makeC = function(){return new C;};

self.nativeConstructor(A);
self.nativeConstructor(B);
self.nativeConstructor(C);
""";

var g;

callFoo(x) {
  // Dominating getInterceptor call should be shared.
  g = x.toString();
  // These call sites are partitioned into pure-dart and native subsets,
  // allowing differences in getInterceptors.
  if (x is D) return x.foo();
  if (x is A) return x.foo();
}

makeAll() => [makeA(), makeB(), makeC(), new D(), new E()];

main() {
  nativeTesting();
  setup();
  /*
  var a = makeA();
  var b = makeB();
  var c = makeC();
  var d = new D();
  var e = new E();
  */
  var x = makeAll();
  var a = x[0];
  var b = x[1];
  var c = x[2];
  var d = x[3];
  var e = x[4];

  var f = callFoo;

  Expect.equals('A.foo', f(a));
  Expect.equals('M2.foo', f(b));
  Expect.equals('C.foo', f(c));
  Expect.equals('M2.foo', f(d));
  Expect.equals('E.foo', f(e));
}
