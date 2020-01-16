// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  int? lateLocalInit;
  int initLateLocal(int value) {
    return lateLocalInit = value;
  }

  late final int lateLocal = initLateLocal(123);

  expect(null, lateLocalInit);
  expect(123, lateLocal);
  expect(123, lateLocalInit);

  local<T>(T value) {
    T? lateGenericLocalInit;
    T initLateGenericLocal(T value) {
      return lateGenericLocalInit = value;
    }

    late final T lateGenericLocal = initLateGenericLocal(value);

    expect(null, lateGenericLocalInit);
    expect(value, lateGenericLocal);
    expect(value, lateGenericLocalInit);
  }

  local<int?>(null);
  local<int?>(42);
  local<int>(42);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
