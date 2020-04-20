// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

late final g;

class C {
  static late final s;
  late final v;
}

main() {
  late final l;

  g = "Lily";
  C.s = "was";
  var c = new C();
  c.v = "here";
  l = "Run, Forrest, run";

  expect("Lily", g);
  expect("was", C.s);
  expect("here", c.v);
  expect("Run, Forrest, run", l);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
