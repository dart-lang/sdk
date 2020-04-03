// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that fast method extraction returns correct closure.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr

import "package:expect/expect.dart";

class A {
  var f;
  A(this.f);
  foo() => 40 + f;
}

class B {
  var f;
  B(this.f);
  foo() => -40 - f;
}

class X {}

class C<T> {
  foo(v) => v is T;
}

class ChaA {
  final magic;
  ChaA(magic) : this.magic = magic;

  foo() {
    Expect.isTrue(this is ChaA);
    Expect.equals("magicA", magic);
    return "A";
  }

  bar() => foo;
}

class ChaB extends ChaA {
  ChaB(magic) : super(magic);

  foo() {
    Expect.isTrue(this is ChaB);
    Expect.equals("magicB", magic);
    return "B";
  }
}

mono(a) {
  var f = a.foo;
  return f();
}

poly(a) {
  var f = a.foo;
  return f();
}

types(a, b) {
  var f = a.foo;
  Expect.isTrue(f(b));
}

cha(a) {
  var f = a.bar();
  return f();
}

extractFromNull() {
  var f = (null).toString;
  Expect.equals("null", f());
}

main() {
  var a = new A(2);
  var b = new B(2);
  for (var i = 0; i < 20; i++) {
    Expect.equals(42, mono(a));
  }

  for (var i = 0; i < 20; i++) {
    Expect.equals(42, poly(a));
    Expect.equals(-42, poly(b));
  }

  var c = new C<X>();
  var x = new X();
  for (var i = 0; i < 20; i++) {
    types(c, x);
  }

  var chaA = new ChaA("magicA");
  for (var i = 0; i < 20; i++) {
    Expect.equals("A", cha(chaA));
  }

  var chaB = new ChaB("magicB");
  for (var i = 0; i < 20; i++) {
    Expect.equals("B", cha(chaB));
  }

  for (var i = 0; i < 20; i++) {
    extractFromNull();
  }
}
