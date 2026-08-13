// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  late int local1;
  local1 = 0;
  expect(0, local1);
  local1 += 2;
  expect(2, local1);

  late int local2 = 1;
  expect(1, local2);
  local2 += 2;
  expect(3, local2);
}

error() {
  late final int local;
  local += 0;
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
