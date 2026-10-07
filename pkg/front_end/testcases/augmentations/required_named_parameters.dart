// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

bool topLevel({required int x, required int y});
augment bool topLevel({required int y, required int x}) => x < y;

class Class {
  final bool value;

  new () : value = false;

  new constructor({required int x, required int y});
  augment new constructor({required int y, required int x}) : value = x < y;

  bool instanceMethod({required int x, required int y});
  augment bool instanceMethod({required int y, required int x}) => x < y;

  static bool staticMethod({required int x, required int y});
  augment static bool staticMethod({required int y, required int x}) => x < y;
}

enum Enum {
  a.constructor(x: 4, y: 5),
  b.constructor(y: 4, x: 5),
  ;

  final bool value;

  new constructor({required int x, required int y});
  augment new constructor({required int y, required int x}) : value = x < y;

  bool instanceMethod({required int x, required int y});
  augment bool instanceMethod({required int y, required int x}) => x < y;

  static bool staticMethod({required int x, required int y});
  augment static bool staticMethod({required int y, required int x}) => x < y;
}

mixin Mixin {
  bool instanceMethod({required int x, required int y});
  augment bool instanceMethod({required int y, required int x}) => x < y;

  static bool staticMethod({required int x, required int y});
  augment static bool staticMethod({required int y, required int x}) => x < y;
}

class MixinApplication = Object with Mixin;

extension Extension on bool {
  bool instanceMethod({required int x, required int y});
  augment bool instanceMethod({required int y, required int x}) => x < y;

  static bool staticMethod({required int x, required int y});
  augment static bool staticMethod({required int y, required int x}) => x < y;
}

extension type ExtensionType(bool value) {
  new constructor({required int x, required int y});
  augment new constructor({required int y, required int x}) : this(x < y);

  bool instanceMethod({required int x, required int y});
  augment bool instanceMethod({required int y, required int x}) => x < y;

  static bool staticMethod({required int x, required int y});
  augment static bool staticMethod({required int y, required int x}) => x < y;
}

main() {
  expect(true, topLevel(x: 4, y: 5));
  expect(false, topLevel(y: 4, x: 5));

  expect(true, Class.constructor(x: 4, y: 5).value);
  expect(false, Class.constructor(y: 4, x: 5).value);

  expect(true, Class().instanceMethod(x: 4, y: 5));
  expect(false, Class().instanceMethod(y: 4, x: 5));

  expect(true, Class.staticMethod(x: 4, y: 5));
  expect(false, Class.staticMethod(y: 4, x: 5));

  expect(true, Enum.a.value);
  expect(false, Enum.b.value);

  expect(true, Enum.a.instanceMethod(x: 4, y: 5));
  expect(false, Enum.a.instanceMethod(y: 4, x: 5));

  expect(true, Enum.staticMethod(x: 4, y: 5));
  expect(false, Enum.staticMethod(y: 4, x: 5));

  expect(true, MixinApplication().instanceMethod(x: 4, y: 5));
  expect(false, MixinApplication().instanceMethod(y: 4, x: 5));

  expect(true, Mixin.staticMethod(x: 4, y: 5));
  expect(false, Mixin.staticMethod(y: 4, x: 5));

  expect(true, false.instanceMethod(x: 4, y: 5));
  expect(false, false.instanceMethod(y: 4, x: 5));

  expect(true, Extension.staticMethod(x: 4, y: 5));
  expect(false, Extension.staticMethod(y: 4, x: 5));

  expect(true, ExtensionType.constructor(x: 4, y: 5).value);
  expect(false, ExtensionType.constructor(y: 4, x: 5).value);

  expect(true, ExtensionType(false).instanceMethod(x: 4, y: 5));
  expect(false, ExtensionType(false).instanceMethod(y: 4, x: 5));

  expect(true, ExtensionType.staticMethod(x: 4, y: 5));
  expect(false, ExtensionType.staticMethod(y: 4, x: 5));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}