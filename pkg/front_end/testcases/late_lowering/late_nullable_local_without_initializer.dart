// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  late int? lateLocal;
  throws(() => lateLocal, 'Read value from uninitialized lateLocal');
  expect(123, lateLocal = 123);
  expect(123, lateLocal);

  local<T>(T? value) {
    late T? lateGenericLocal;
    throws(() => lateGenericLocal,
        'Read value from uninitialized lateGenericLocal');
    expect(value, lateGenericLocal = value);
    expect(value, lateGenericLocal);
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
