// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_js_helper";
import "package:expect/expect.dart";

// Test that native classes and ordinary Dart classes can both use the same
// ordinary Dart classes as a mixin.

@Native("A")
class A {
  final String aa;
  foo() => "A-foo $aa";
  baz() => "A-baz $aa";
}

@Native("B")
class B extends A with M {
  bar() => 'B-bar -> ${baz()}';
  get mm => 'B.mm($aa)';
}

class M {
  foo() => "M-foo ${this.mm}";
  bar() => "M-bar ${this.mm}";
  get mm => 'M.mm';
}

class C {
  final String cc = 'cc';
  foo() => 'C-foo $cc';
  baz() => 'C-baz $cc';
}

class D extends C with M {
  bar() => 'D-bar -> ${baz()}';
  get mm => 'D.mm($cc)';
}


makeA() native;
makeB() native;

void setup() native """
function A() {this.aa = 'aa'}
function B() {this.aa = 'bb'}
makeA = function(){return new A;};
makeB = function(){return new B;};
""";

main() {
  setup();
  var things = [makeA, makeB, () => new C(), () => new D(), () => new M()]
      .map((f)=>f())
      .toList();
  var a = things[0];
  var b = things[1];
  var c = things[2];
  var d = things[3];
  var m = things[4];

  Expect.equals("M-foo M.mm", m.foo());
  Expect.equals("M-bar M.mm", m.bar());
  Expect.throws(() => m.baz(), (error) => error is NoSuchMethodError);
  Expect.isFalse(m is A);
  Expect.isFalse(m is B);
  Expect.isFalse(m is C);
  Expect.isFalse(m is D);
  Expect.isTrue(m is M);

  Expect.equals("A-foo aa", a.foo());
  Expect.throws(() => a.bar(), (error) => error is NoSuchMethodError);
  Expect.equals("A-baz aa", a.baz());
  Expect.isTrue(a is A);
  Expect.isFalse(a is B);
  Expect.isFalse(a is C);
  Expect.isFalse(a is D);
  Expect.isFalse(a is M);

  Expect.equals("M-foo B.mm(bb)", b.foo());
  Expect.equals("B-bar -> A-baz bb", b.bar());
  Expect.equals("A-baz bb", b.baz());
  Expect.isTrue(b is A);
  Expect.isTrue(b is B);
  Expect.isFalse(b is C);
  Expect.isFalse(b is D);
  Expect.isTrue(b is M);

  Expect.equals("C-foo cc", c.foo());
  Expect.throws(() => c.bar(), (error) => error is NoSuchMethodError);
  Expect.equals("C-baz cc", c.baz());
  Expect.isFalse(c is A);
  Expect.isFalse(c is B);
  Expect.isTrue(c is C);
  Expect.isFalse(c is D);
  Expect.isFalse(c is M);

  Expect.equals("M-foo D.mm(cc)", d.foo());
  Expect.equals("D-bar -> C-baz cc", d.bar());
  Expect.equals("C-baz cc", d.baz());
  Expect.isFalse(d is A);
  Expect.isFalse(d is B);
  Expect.isTrue(d is C);
  Expect.isTrue(d is D);
  Expect.isTrue(d is M);

}
