// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  late final int? lateLocal;

  throws(() => lateLocal, 'Read value from uninitialized lateLocal');
  expect(123, lateLocal = 123);
  expect(123, lateLocal);
  throws(() => lateLocal = 124, 'Write value to initialized lateLocal');
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}

throws(f(), String message) {
  dynamic value;
  try {
    value = f();
  } catch (e) {
    print(e);
    return;
  }
  throw '$message: $value';
}
