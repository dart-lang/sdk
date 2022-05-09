// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum C {
  a(1, 2, z: 3),
  b(z: 3, 1, 2),
  c(1, z: 3, 2),
  d.named1(1, 2, 3),
  e.named2(1, 2, 3),
  f.named3(1, 2, 3),
  ;

  final String log;

  const C(int x, int y, {int z = 42})
    : this.log = "x=$x, y=$y, z=$z";

  const C.named1(int x, int y, int z) : this(x, y, z: z);
  const C.named2(int x, int y, int z) : this(x, z: z, y);
  const C.named3(int x, int y, int z) : this(z: z, x, y);
}

main() {
  expect("x=1, y=2, z=3", C.a.log);
  expect("x=1, y=2, z=3", C.b.log);
  expect("x=1, y=2, z=3", C.c.log);
  expect("x=1, y=2, z=3", C.d.log);
  expect("x=1, y=2, z=3", C.e.log);
  expect("x=1, y=2, z=3", C.f.log);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}