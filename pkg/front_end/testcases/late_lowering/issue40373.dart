// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  num pi = 3.14;
  late num p1 = this.pi;
  late final p2 = this.pi;
}

main() {
  expect(3.14, new C().p1);
  expect(3.14, new C().p2);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
