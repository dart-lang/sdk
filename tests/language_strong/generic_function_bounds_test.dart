// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';
import 'package:expect/expect.dart';

void testInstantiateToBounds() {
  f<T extends num, U extends T>() => [T, U];
  g<T extends List<U>, U extends int>() => [T, U];
  h<T extends num, U extends T>(T x, U y) => h.runtimeType.toString();

  Expect.listEquals((f as dynamic)(), [num, num]);
  Expect.equals((g as dynamic)().join('|'), 'List<int>|int');
  Expect.equals((h as dynamic)(null, null),
      '<T extends num, U extends T>(T, U) -> String');

  i<T extends Iterable<T>>() => null;
  j<T extends Iterable<S>, S extends T>() => null;
  Expect.throws(() => (i as dynamic)(),
      (e) => '$e'.contains('Instantiate to bounds'));
  Expect.throws(() => (j as dynamic)(),
      (e) => '$e'.contains('Instantiate to bounds'));
}

void testChecksBound() {
  f<T extends num>(T x) => x;
  Expect.equals((f as dynamic)(42), 42);
  Expect.throws(() => (f as dynamic)('42'));

  g<T extends U, U extends num>(T x, U y) => x;
  Expect.equals((g as dynamic)(42.0, 100), 42.0);
  Expect.throws(() => (g as dynamic)('hi', 100));
}

typedef G<U> = T Function<T extends U>(T x);

void testSubtype() {
  f<T extends num>(T x) => x + 2;

  dynamic d = f;
  Expect.equals(d(40.0), 42.0);
  Expect.equals((f as G<int>)(40), 42);
  Expect.equals((d as G<int>)(40), 42);
  Expect.equals((f as G<double>)(40.0), 42.0);
  Expect.equals((d as G<double>)(40.0), 42.0);

  d as G<Null>;
  Expect.throws(() => d as G);
  Expect.throws(() => d as G<Object>);
  Expect.throws(() => d as G<String>);
}

void testToString() {
  // TODO(jmesserly): I don't think the cast on `y` should be required.
  num f<T extends num, U extends T>(T x, U y) => min(x, y as num);
  num g<T, U>(T x, U y) => max(x as num, y as num);
  String h<T, U>(T x, U y) => h.runtimeType.toString();
  Expect.equals(f.runtimeType.toString(),
      '<T extends num, U extends T>(T, U) -> num');
  Expect.equals(g.runtimeType.toString(), '<T, U>(T, U) -> num');
  Expect.equals(h(42, 123.0), '<T, U>(T, U) -> String');
}

main() {
  testInstantiateToBounds();
  testToString();
  testChecksBound();
  testSubtype();
}
