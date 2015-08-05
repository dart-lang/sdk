// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Basic test for tear-off constructor closures.

import "package:expect/expect.dart";

class A {
  // Implicit constructor A();
  var f1 = "A.f1";
}

class P {
  var x, y;
  P(this.x, this.y);
  factory P.origin() { return new P(0,0); }
  factory P.ursprung() = P.origin;
  P.onXAxis(x) : this(x, 0);
}

class C<T> {
  T f1;
  C(T p) : f1 = p;
  C.n([T p]) : f1 = p;
  listMaker() { return new List<T>#; }  // Closurize type parameter.
}


testMalformed() {
  Expect.throws(() => new NoSuchClass#);
  Expect.throws(() => new A#noSuchContstructor);
}

testA() {
  var cc = new A#;  // Closurize implicit constructor.
  var o = cc();
  Expect.equals("A.f1", o.f1);
  Expect.equals("A.f1", (new A#)().f1);
  Expect.throws(() => new A#foo);
}

testP() {
  var cc = new P#origin;
  var o = cc();
  Expect.equals(0, o.x);
  cc = new P#ursprung;
  o = cc();
  Expect.equals(0, o.x);
  cc = new P#onXAxis;
  o = cc(5);
  Expect.equals(0, o.y);
  Expect.equals(5, o.x);
  Expect.throws(() => cc(1, 1));  // Too many arguments.
}

testC() {
  var cc = new C<int>#;
  var o = cc(5);
  Expect.equals("int", "${o.f1.runtimeType}");
  Expect.throws(() => cc());  // Missing constructor parameter.

  cc = new C<String>#n;
  o = cc("foo");
  Expect.equals("String", "${o.f1.runtimeType}");
  o = cc();
  Expect.equals(null, o.f1);

  cc = o.listMaker();
  Expect.isTrue(cc is Function);
  var l = cc();
  Expect.equals("List<String>", "${l.runtimeType}");
}

main() {
  testA();
  testC();
  testP();
  testMalformed();
}
