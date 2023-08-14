// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension _ on int {
  int method(int i) => this + i;
}

method(dynamic d) => switch (d) {
      int(:var method) => method(d),
      _ => 0,
    };

main() {
  expect(42, method(21));
  expect(0, method('21'));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
