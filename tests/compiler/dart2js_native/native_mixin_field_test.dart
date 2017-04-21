// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "native_testing.dart";

// Test that native classes can use ordinary Dart classes with fields
// as mixins.

@Native("A")
class A {
  var foo;
}

@Native("B")
class B extends A with M1, M2 {
  var bar;
}

class M1 {
  var baz; // This field is not a native field, even when mixed in.
}

class M2 {
  var bar;
  var buz;
}

A makeA() native;
B makeB() native;

void setup() native """
function A() {this.foo='A-foo';}
function B() {A.call(this);this.bar='B-bar';this.baz='M1-baz';}
makeA = function(){return new A;};
makeB = function(){return new B;};

self.nativeConstructor(A);
self.nativeConstructor(B);
""";

main() {
  nativeTesting();
  setup();
  A a = makeA();
  Expect.equals("A-foo", a.foo);
  Expect.throws(() => a.bar, (e) => e is NoSuchMethodError);
  Expect.throws(() => a.baz, (e) => e is NoSuchMethodError);
  Expect.throws(() => a.buz, (e) => e is NoSuchMethodError);

  B b = makeB();
  Expect.equals("A-foo", b.foo);
  Expect.equals("B-bar", b.bar);
  // Expect.equals("M1-baz", b.baz);  // not true, see M1.
  Expect.isNull(b.baz); // native b.baz is not the same as dart b.baz.
  Expect.isNull(b.buz);

  M1 m1 = new M1();
  Expect.throws(() => m1.foo, (e) => e is NoSuchMethodError);
  Expect.throws(() => m1.bar, (e) => e is NoSuchMethodError);
  Expect.isNull(m1.baz);
  Expect.throws(() => m1.buz, (e) => e is NoSuchMethodError);

  M2 m2 = new M2();
  Expect.throws(() => m2.foo, (e) => e is NoSuchMethodError);
  Expect.isNull(m2.bar);
  Expect.throws(() => m2.baz, (e) => e is NoSuchMethodError);
  Expect.isNull(m2.buz);
}
