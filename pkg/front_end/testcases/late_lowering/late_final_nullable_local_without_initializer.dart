// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  late final int? lateLocal;

  throws(() => lateLocal, 'Read value from uninitialized lateLocal');
  // This `if` test prevents flow analysis from realizing that we
  // unconditionally write to `lateLocal`, so that we can write to it again
  // later without a static error.
  if (1 == 1) {
    expect(123, lateLocal = 123);
  }
  expect(123, lateLocal);
  throws(() => lateLocal = 124, 'Write value to initialized lateLocal');

  local<T>(T? value) {
    late final T? lateGenericLocal;

    throws(() => lateGenericLocal,
        'Read value from uninitialized lateGenericLocal');
    // This `if` test prevents flow analysis from realizing that we
    // unconditionally write to `lateLocal`, so that we can write to it again
    // later without a static error.
    if (1 == 1) {
      expect(value, lateGenericLocal = value);
    }
    expect(value, lateGenericLocal);
    throws(() => lateGenericLocal = value,
        'Write value to initialized lateGenericLocal');
  }

  local<int?>(null);
  local<int?>(0);
  local<int>(null);
  local<int>(0);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}

throws(f(), String message) {
  dynamic value;
  try {
    value = f();
  } on LateInitializationError catch (e) {
    print(e);
    return;
  }
  throw '$message: $value';
}
