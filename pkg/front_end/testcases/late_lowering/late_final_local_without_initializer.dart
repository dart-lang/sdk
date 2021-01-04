// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  bool b = (() => false)();
  late final int lateLocal;

  if (b) {
    // Pretend to assign to confuse flow analysis for the read below.
    lateLocal = 123;
  }
  throws(() => lateLocal, 'Read value from uninitialized lateLocal');
  if (!b) {
    // Pretend to not assign to confuse flow analysis for the write below.
    expect(123, lateLocal = 123);
    expect(123, lateLocal);
  }
  throws(() => lateLocal = 124, 'Write value to initialized lateLocal');

  local<T>(T value) {
    late final T lateGenericLocal;

    if (b) {
      // Pretend to assign to confuse flow analysis for the read below.
      lateGenericLocal = value;
    }
    throws(() => lateGenericLocal,
        'Read value from uninitialized lateGenericLocal');

    if (!b) {
      // Pretend to not assign to confuse flow analysis for the write below.
      expect(value, lateGenericLocal = value);
      expect(value, lateGenericLocal);
    }
    throws(() => lateGenericLocal = value,
        'Write value to initialized lateGenericLocal');
  }

  local<int?>(null);
  local<int?>(42);
  local<int>(42);
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
