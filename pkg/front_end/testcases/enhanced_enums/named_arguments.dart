// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E0 {
  one(1, bar: 1),
  two(2, bar: 2);

  final int foo;
  final int bar;

  const E0(this.foo, {required this.bar});
}

enum E1<X> {
  one(foo: "1"),
  two(foo: 2);

  final X foo;

  const E1({required this.foo});
}

enum E2<X, Y, Z> {
  one(1, bar: "1", baz: 3.14),
  two("2", baz: 3.14, bar: 2),
  three(3.0, bar: false);

  final X foo;
  final Y bar;
  final Z? baz;

  const E2(this.foo, {required this.bar, this.baz = null});
}

main() {}
