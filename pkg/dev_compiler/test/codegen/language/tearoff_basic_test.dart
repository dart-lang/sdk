// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Basic test for tear-off closures.

import "package:expect/expect.dart";
import "tearoff_basic_lib.dart" as P;
import "tearoff_basic_lib.dart" deferred as D;

class C {
  var v = 99;
  final fv = 444;

  operator + (a) { return v + a; }
  get sugus => "sugus";
  set frosch(a) { v = "ribbit $a"; }
  foo() => "kuh";

  static var st;
  static final stfin = 1000;
  static stfoo([p1 = 100]) => p1 * 10;
  static get stg => "stg";
  static set sts(x) { st = x; }
}


testStatic() {
  // Closurize static variable.
  var a = C#st=;
  a(100);
  Expect.equals(100, C.st);
  var b = C#st;
  Expect.equals(100, b());

  // Closurize static final variable.
  a = C#stfin;
  Expect.equals(1000, a());
  Expect.throws(() => C#stfin= );  // Final variable has no setter.

  // Closurize static method.
  a = C#stfoo;
  Expect.equals(1000, a());
  Expect.equals(90, a(9));

  // Closurize static getter.
  a = C#stg;
  Expect.equals("stg", a());

  // Closurize static setter.
  Expect.throws(() => C#sts);  // No setter/method named sts exists.
  a = C#sts=;
  a("pflug");
  Expect.equals("pflug", C.st);

  // Can't closurize instance method via class literal.
  Expect.throws(() => C#foo);

  // Extracted closures must be equal.
  Expect.isTrue(C#st == C#st);
  Expect.isTrue(C#st= == C#st=);
  Expect.isTrue(C#stfin == C#stfin);
  Expect.isTrue(C#stfoo == C#stfoo);
  Expect.isTrue(C#stg == C#stg);
  Expect.isTrue(C#sts= == C#sts=);
}

testInstance() {
  var o = new C();
  var p = new C();
  var a, b;

  // Closurize instance variable.
  a = o#v;
  Expect.equals(99, a());
  b = p#v=;
  b(999);
  Expect.equals(999, p.v);
  Expect.equals(99, a());

  // Closurize final instance variable.
  Expect.throws(() => o#fv=);  // Final variable has not setter.
  a = o#fv;
  Expect.equals(444, a());

  // Closurize instance method.
  a = o#foo;
  Expect.equals("kuh", a());

  // Closurize operator.
  a = o#+;
  Expect.equals(100, o + 1);
  Expect.equals(100, a(1));

  // Closurize instance getter.
  a = o#sugus;
  Expect.equals("sugus", a());
  Expect.throws(() => o#sugus=);

  // Closurize instance setter.
  a = o#frosch=;
  a("!");
  Expect.equals("ribbit !", o.v);
  Expect.throws(() => o#frosch);

  // Extracted closures must be equal.
  Expect.isTrue(o#v == o#v);
  Expect.isTrue(o#v= == o#v=);
  Expect.isTrue(o#fv == o#fv);
  Expect.isTrue(o#foo == o#foo);
  Expect.isTrue(o#+ == o#+);
  Expect.isTrue(o#sugus == o#sugus);
  Expect.isTrue(o#frosch= == o#frosch=);
}

testPrefix() {
  // Closurize top-level variable.
  var a = P#cvar;
  Expect.equals(6, a());
  var b = P#cvar=;
  b(7);
  Expect.equals(7, a());

  // Closurize final top-level variable.
  a = P#cfinvar;
  Expect.equals("set in stone", a());
  Expect.throws(() => P#cfinvar=);

  // Closurize top-level function.
  a = P#cfunc;
  Expect.equals("cfunc", a());

  // Closurize top-level getter.
  a = P#cget;
  Expect.equals("cget", a());

  // Closurize top-level getter.
  a = P#cset=;
  a(99);
  Expect.equals(99, P.cvar);

  Expect.throws(() => P#ZZ);  // Cannot closurize class.

  // Extracted closures must be equal.
  Expect.isTrue(P#cvar == P#cvar);
  Expect.isTrue(P#cvar= == P#cvar=);
  Expect.isTrue(P#cfinvar == P#cfinvar);
  Expect.isTrue(P#cfunc == P#cfunc);
  Expect.isTrue(P#cget == P#cget);
  Expect.isTrue(P#cset= == P#cset=);
}

testDeferred() {
  Expect.throws(() => D#cfunc);
  D.loadLibrary().then((_) {
    var a = D#cfunc;
    Expect.equals("cfunc", a());
  });
}

main() {
  testStatic();
  testInstance();
  testPrefix();
  testDeferred();
}
