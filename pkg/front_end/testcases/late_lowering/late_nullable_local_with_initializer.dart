// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int? lateLocalInit() => 123;

main() {
  late int? lateLocal = lateLocalInit();

  expect(123, lateLocal);
  expect(124, lateLocal = 124);
  expect(124, lateLocal);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
