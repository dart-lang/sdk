// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "native_testing.dart";

// Test that native classes can use ordinary Dart classes with fields
// as mixins.

@Native("A")
class A {
  var foo;
}

class A1 {
  get foo => 42;
  set foo(value) {}
}

@Native("B")
class B extends A with M1, M2 {
  var bar;
}

class B1 extends A1 with M1, M2 {
  get bar => 42;
  set bar(value) {}
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

void setup() {
  JS('', r"""
(function(){
  function A() {this.foo='A-foo';}
  function B() {A.call(this);this.bar='B-bar';this.baz='M1-baz';}
  makeA = function(){return new A()};
  makeB = function(){return new B()};

  self.nativeConstructor(A);
  self.nativeConstructor(B);
})()""");
}

@pragma('dart2js:assumeDynamic')
confuse(x) => x;

main() {
  nativeTesting();
  setup();
  dynamic a = makeA();
  a ??= new A1();
  Expect.equals("A-foo", confuse(a).foo);
  Expect.throws(() => confuse(a).bar, (e) => e is NoSuchMethodError);
  Expect.throws(() => confuse(a).baz, (e) => e is NoSuchMethodError);
  Expect.throws(() => confuse(a).buz, (e) => e is NoSuchMethodError);

  dynamic b = makeB();
  b ??= new B1();
  Expect.equals("A-foo", confuse(b).foo);
  Expect.equals("B-bar", confuse(b).bar);
  // Expect.equals("M1-baz", b.baz);  // not true, see M1.
  Expect.isNull(confuse(b).baz); // native b.baz is not the same as dart b.baz.
  Expect.isNull(confuse(b).buz);

  M1 m1 = new M1();
  Expect.throws(() => confuse(m1).foo, (e) => e is NoSuchMethodError);
  Expect.throws(() => confuse(m1).bar, (e) => e is NoSuchMethodError);
  Expect.isNull(m1.baz);
  Expect.throws(() => confuse(m1).buz, (e) => e is NoSuchMethodError);

  M2 m2 = new M2();
  Expect.throws(() => confuse(m2).foo, (e) => e is NoSuchMethodError);
  Expect.isNull(confuse(m2).bar);
  Expect.throws(() => confuse(m2).baz, (e) => e is NoSuchMethodError);
  Expect.isNull(confuse(m2).buz);
}
