// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  A nonNullableField = const A();
  A get nonNullableProperty => nonNullableField;
  void set nonNullableProperty(A value) {
    nonNullableField = value;
  }

  A nonNullableMethod() => nonNullableField;
}

class A {
  const A();

  A get nonNullableProperty => this;
}

main() {
  Class? c;
  throws(() => c.nonNullableField);
  expect(null, c?.nonNullableField);
  expect(null, c?.nonNullableField.nonNullableProperty);
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}

throws(void Function() f) {
  try {
    f();
  } catch (e) {
    return;
  }
  throw 'Expected throws.';
}
