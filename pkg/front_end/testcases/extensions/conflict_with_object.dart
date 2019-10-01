// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension Extension on String {
  int get noSuchMethod => 42;
  void set hashCode(int value) {}
  int runtimeType() {}
  operator ==(other) => false;
  static String toString() => 'Foo';
}

main() {
  int value;
  expect(true, "".noSuchMethod is Function);
  value = Extension("").noSuchMethod;
  Extension("").hashCode = 42;
  expect(true, "".runtimeType is Type);
  expect(true, Extension("").runtimeType is Function);
  value = Extension("").runtimeType();
  expect(true, "" == "");
  expect('Foo', Extension.toString());
}

errors() {
  int value;
  value = "".noSuchMethod;
  "".hashCode = 42;
  value = "".runtimeType;
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Mismatch: expected=$expected, actual=$actual';
  }
}
