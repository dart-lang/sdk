// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int count = 0;

class A {
  int get bar {
    count++;
    print('OK');
    return 42;
  }
}

main() {
  var A(bar: _) = A();
  expect(1, count);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
