// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib2.dart';

main() {
  ExtensionType e1 = ExtensionType(42);
  expect(42, e1.instanceMethod());
  expect(42, (e1.instanceMethod)());
  expect(43, e1 + 1);
  expect(42, e1.it);
  expect(42, e1.instanceGetter);
  e1.instanceSetter = 43;

  expect(87, ExtensionType.staticMethod());
  expect(87, (ExtensionType.staticMethod)());
  expect(123, ExtensionType.staticField);
  expect(123, ExtensionType.staticGetter);
  ExtensionType.staticSetter = 124;
  expect(124, ExtensionType.staticField);
  expect(124, ExtensionType.staticGetter);

  expect(42, (ExtensionType.new)(42));
  expect(43, ExtensionType.named(42));
  expect(43, (ExtensionType.named)(42));
  expect(44, ExtensionType.redirectingGenerative(42));
  expect(44, (ExtensionType.redirectingGenerative)(42));
  expect(45, ExtensionType.fact(42));
  expect(45, (ExtensionType.fact)(42));
  expect(42, ExtensionType.redirectingFactory(42));
  expect(42, (ExtensionType.redirectingFactory)(42));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
