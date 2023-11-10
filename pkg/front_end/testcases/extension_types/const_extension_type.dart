// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by b
// BSD-style license that can be found in the LICENSE file.

class Class<T> {
  const Class();
}

extension type const ExtensionType<T>(T id) {}

const a1 = Class<int>;
const a2 = ExtensionType<Class<int>>;
const a3 = Class<bool>;
const a4 = ExtensionType<Class<bool>>;

const b1 = const Class<int>();
const b2 = const ExtensionType<Class<int>>(Class<int>());
const b3 = const Class<bool>();
const b4 = const ExtensionType<Class<bool>>(Class<bool>());

main() {
  expect(true, identical(a1, a2));
  expect(true, identical(a3, a4));
  expect(false, identical(a1, a3));
  expect(false, identical(a2, a4));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}