// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing the ternary operator.

import "package:expect/expect.dart";

// Test that `Null` acts like the bottom type - less than any other type.

typedef R Fun<A, R>(A argument);

class C<T> {
  const C();
  T returns() => null;
  void accepts(T x) {}
}

class NullBound<T extends num> {}

class ListBound<T extends Iterable<Null>> {}

main() {
  testClassTypes();
  testFunctionTypes();
}

void testClassTypes() {
  var cn = new C<Null>();

  Expect.isTrue(cn is C<Null>, "C<Null> is C<Null>");
  Expect.isTrue(cn is C<Object>, "C<Null> is C<Object>");
  Expect.isTrue(cn is C<int>, "C<Null> is C<int>");

  Expect.isNotNull(cn as C<Null>, "C<Null> as C<Null>");
  Expect.isNotNull(cn as C<Object>, "C<Null> as C<Object>");
  Expect.isNotNull(cn as C<int>, "C<Null> as C<int>");

  var ccn = new C<C<Null>>();

  Expect.isTrue(ccn is C<C<Null>>);
  Expect.isTrue(ccn is C<C<Object>>);
  Expect.isTrue(ccn is C<C<int>>);

  Expect.isNotNull(ccn as C<C<Null>>);
  Expect.isNotNull(ccn as C<C<Object>>);
  Expect.isNotNull(ccn as C<C<int>>);

  var ci = new C<int>();
  Expect.isFalse(ci is C<Null>);

  var co = new C<Object>();
  Expect.isFalse(co is C<Null>);

  if (!typeAssertionsEnabled) return;

  List<int> li1 = const <Null>[];

  C<Null> x1 = cn;
  C<Object> x2 = cn;

  Expect.identical(x1, cn);
  Expect.identical(x2, cn);

  const C<Null> cocn = const C<Null>();
  const C<Object> coco = cocn;
  const C<int> coci = cocn;

  Expect.identical(cocn, coco);
  Expect.identical(cocn, coci);

  Expect.throws(() {
    Null x = "string" as dynamic;
    use(x); // Avoid "x unused" warning.
  });

  Expect.throws(() {
    Null x = new Object();
    use(x); // Avoid "x unused" warning.
  });

  NullBound<int> nb = new NullBound<Null>(); // Should not fail.
  use(nb); // Avoid "nb unused" warning.
  ListBound<List<Null>> lb = new ListBound<Null>(); // Should not fails
  use(lb); // Avoid "nb unused" warning.
}

void testFunctionTypes() {
  T1 t1 = new T1();
  T2 t2 = new T2();
  T1 t = t2;

  Fun<int, Null> f1 = t1.foo;
  Fun<Null, int> f2 = t.bar;
  f1 = t1.baz;
  f2 = t.qux;
  use(f1);
  use(f2);

  var l = new List<Fun<Null, Null>>();
  Expect.isTrue(l is List<Fun<Null, int>>);
  l = new List<Fun<int, int>>();
  Expect.isTrue(l is List<Fun<Null, num>>);

  Expect.isTrue(((int _) => null) is Fun<int, Null>);

  Null fun(int x) => null;
  Fun<Null, int> fun2 = fun; // Safe assignment.
  if (fun2 is Fun<int, Null>) {
    // If int->Null is *subtype* of Null->int (which it should be),
    // then type promotion succeeds.
    // If type promotion succeeds, the static type is int->Null, otherwise
    // it's Null->int.
    fun2(42); // Should not give a warning after type promotion.
    fun2(null).abs(); // //# 03: runtime error
  }
}

class T1 {
  Null foo(int x) => null;
  int bar(Null x) => null;
  Null baz(int x) => null;
  int qux(Null x) => null;
}

class T2 extends T1 {
  Null foo(Null x) => null;
  Null bar(Null x) => null;
  int baz(int x) => x;
  int qux(int x) => x;
}

// Avoid "variable not used" warnings.
use(x) {
  return identical(x, x);
}
