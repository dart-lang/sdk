// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type V<X1 extends num, X2 extends Object>(X1 id) {}

typedef V<int, int> Foo<T extends V<num, Object>>(V<int, int> v);
typedef IntNumV = V<int, num>;

V<int, int> foo<T extends V<num, Object>>(T t) => t as V<int, int>;

class C<T extends V<num, Object>> {
  Foo<T> f = foo<V<int, int>>;
}

main() {
  IntNumV v = IntNumV(42);
  expect(42, v.id);

  expect(v, foo(v));
  expect(V<int, int>(0), C<V<int, int>>().f(V<int, int>(0)));
  expect(V(1), C<V<int, int>>().f(V<int, int>(1)));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}