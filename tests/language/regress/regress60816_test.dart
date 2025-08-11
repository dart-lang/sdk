// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/60816.
//
// Verify that constructor tear-offs properly convert function type arguments
// into instance type parameters when allocating an object.

import "package:expect/expect.dart";

class A<T> {
  T f1;
  A(this.f1);
  Type getT() => T;
}

class B<S> extends A<A<S>> {
  S f2;
  B(this.f2) : super(A(f2));
  Type getS() => S;
}

class C extends A<String> {
  String f3;
  C(this.f3) : super(f3);
}

final newA = A.new;
final newAOfInt = A<int>.new;
final newAOfDyn = A<dynamic>.new;

final newB = B.new;
final newBOfInt = B<int>.new;
final newBOfDyn = B<dynamic>.new;

final newC = C.new;

void main() {
  final a1 = newA<double>(42);
  Expect.type<A<double>>(a1);
  Expect.equals(double, a1.getT());

  final a2 = newA(42 as dynamic);
  Expect.type<A<dynamic>>(a2);
  Expect.equals(dynamic, a2.getT());

  final a3 = newAOfInt(42);
  Expect.type<A<int>>(a3);
  Expect.equals(int, a3.getT());

  final a4 = newAOfDyn(42);
  Expect.type<A<dynamic>>(a4);
  Expect.equals(dynamic, a4.getT());

  final b1 = newB<num>(42);
  Expect.type<B<num>>(b1);
  Expect.type<A<A<num>>>(b1);
  Expect.equals(num, b1.getS());
  Expect.equals(A<num>, b1.getT());

  final b2 = newB(42 as dynamic);
  Expect.type<B>(b2);
  Expect.type<A<A>>(b2);
  Expect.equals(dynamic, b2.getS());
  Expect.equals(A, b2.getT());

  final b3 = newBOfInt(42);
  Expect.type<B<int>>(b3);
  Expect.type<A<A<int>>>(b3);
  Expect.equals(int, b3.getS());
  Expect.equals(A<int>, b3.getT());

  final b4 = newBOfDyn(42);
  Expect.type<B>(b4);
  Expect.type<A<A>>(b4);
  Expect.equals(dynamic, b4.getS());
  Expect.equals(A, b4.getT());

  final c1 = newC('42');
  Expect.type<C>(c1);
  Expect.type<A<String>>(c1);
  Expect.equals(String, c1.getT());
}
