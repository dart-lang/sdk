// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that a record type can be passed as a type argument whose bound is
// another type argument that's instantiated with a typedef for a record type
// (or for `Record`), when the record type is a strict subtype of that typedef.

import 'package:expect/expect.dart';

typedef R = (num, String);
typedef RN = (num, {Object foo});
typedef Pair<T> = (T, T);
typedef RNullable = (num,)?;
typedef Rec = Record;

class C<X, Y extends X> {}

typedef Alias<X, Y extends X> = C<X, Y>;

extension type E<X, Y extends X>(int i) {}

class M {
  Type m<X, Y extends X>() => Y;
}

Type f<X, Y extends X>() => Y;

Type typeOf<T>() => T;

void testClass() {
  Expect.type<C<R, (int, String)>>(C<R, (int, String)>());
  Expect.type<C<RN, (int, {String foo})>>(C<RN, (int, {String foo})>());
  Expect.type<C<Pair<num>, (int, double)>>(C<Pair<num>, (int, double)>());
  Expect.type<C<RNullable, (int,)>>(C<RNullable, (int,)>());
  Expect.type<C<Rec, (int, String)>>(C<Rec, (int, String)>());
}

void testTypeAlias() {
  Expect.type<Alias<R, (int, String)>>(Alias<R, (int, String)>());
  Expect.type<Alias<RN, (int, {String foo})>>(Alias<RN, (int, {String foo})>());
  Expect.type<Alias<Pair<num>, (int, double)>>(
    Alias<Pair<num>, (int, double)>(),
  );
  Expect.type<Alias<RNullable, (int,)>>(Alias<RNullable, (int,)>());
  Expect.type<Alias<Rec, (int, String)>>(Alias<Rec, (int, String)>());
}

void testExtensionType() {
  E<R, (int, String)> e1 = E<R, (int, String)>(1);
  E<RN, (int, {String foo})> e2 = E<RN, (int, {String foo})>(2);
  E<Pair<num>, (int, double)> e3 = E<Pair<num>, (int, double)>(3);
  E<RNullable, (int,)> e4 = E<RNullable, (int,)>(4);
  E<Rec, (int, String)> e5 = E<Rec, (int, String)>(5);
  Expect.listEquals([1, 2, 3, 4, 5], [e1.i, e2.i, e3.i, e4.i, e5.i]);
}

void testFunction() {
  Expect.equals(typeOf<(int, String)>(), f<R, (int, String)>());
  Expect.equals(typeOf<(int, {String foo})>(), f<RN, (int, {String foo})>());
  Expect.equals(typeOf<(int, double)>(), f<Pair<num>, (int, double)>());
  Expect.equals(typeOf<(int,)>(), f<RNullable, (int,)>());
  Expect.equals(typeOf<(int, String)>(), f<Rec, (int, String)>());
}

void testMethod() {
  var m = M();
  Expect.equals(typeOf<(int, String)>(), m.m<R, (int, String)>());
  Expect.equals(typeOf<(int, {String foo})>(), m.m<RN, (int, {String foo})>());
  Expect.equals(typeOf<(int, double)>(), m.m<Pair<num>, (int, double)>());
  Expect.equals(typeOf<(int,)>(), m.m<RNullable, (int,)>());
  Expect.equals(typeOf<(int, String)>(), m.m<Rec, (int, String)>());
}

void main() {
  testClass();
  testTypeAlias();
  testExtensionType();
  testFunction();
  testMethod();
}
