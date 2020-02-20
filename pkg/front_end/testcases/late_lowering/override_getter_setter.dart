// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Derived from tests/co19/src/LanguageFeatures/nnbd/late_A07_t01.dart

class A {
  late final int x;
  late final int? y;
}

class B extends A {
  int get x => 1;
  int? get y => 1;
}

class C extends A {
  late final int x = 2;
  late final int? y = 2;
}

main() {
  B b = new B();
  b.x = 3;
  C c = new C();
  throws(() => b.x = 14, "Write to B.x");
  c.x = 3;
  throws(() => c.x = 14, "Write to C.x");
  expect(1, b.x);
  expect(2, c.x);

  b.y = 3;
  throws(() => b.y = 14, "Write to B.y");
  c.y = 3;
  throws(() => c.y = 14, "Write to C.y");
  expect(1, b.y);
  expect(2, c.y);
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
