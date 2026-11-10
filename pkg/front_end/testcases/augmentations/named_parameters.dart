// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

bool topLevel({int x, int y});
augment bool topLevel({int y = 5, int x = 6}) => x < y;

class Class {
  final bool value;

  new () : value = false;

  new constructor({int x, int y});
  augment new constructor({int y = 5, int x = 6}) : value = x < y;

  bool instanceMethod({int x, int y});
  augment bool instanceMethod({int y = 5, int x = 6}) => x < y;

  static bool staticMethod({int x, int y});
  augment static bool staticMethod({int y = 5, int x = 6}) => x < y;
}

enum Enum {
  a.constructor(x: 4),
  b.constructor(y: 4, x: 5),
  ;

  final bool value;

  new constructor({int x, int y});
  augment new constructor({int y = 5, int x = 6}) : value = x < y;

  bool instanceMethod({int x, int y});
  augment bool instanceMethod({int y = 5, int x = 6}) => x < y;

  static bool staticMethod({int x, int y});
  augment static bool staticMethod({int y = 5, int x = 6}) => x < y;
}

mixin Mixin {
  bool instanceMethod({int x, int y});
  augment bool instanceMethod({int y = 5, int x = 6}) => x < y;

  static bool staticMethod({int x, int y});
  augment static bool staticMethod({int y = 5, int x = 6}) => x < y;
}

class MixinApplication = Object with Mixin;

extension Extension on bool {
  bool instanceMethod({int x, int y});
  augment bool instanceMethod({int y = 5, int x = 6}) => x < y;

  static bool staticMethod({int x, int y});
  augment static bool staticMethod({int y = 5, int x = 6}) => x < y;
}

extension type ExtensionType(bool value) {
  new constructor({int x, int y});
  augment new constructor({int y = 5, int x = 6}) : this(x < y);

  bool instanceMethod({int x, int y});
  augment bool instanceMethod({int y = 5, int x = 6}) => x < y;

  static bool staticMethod({int x, int y});
  augment static bool staticMethod({int y = 5, int x = 6}) => x < y;
}

main() {
  expect(true, topLevel(x: 4));
  expect(false, topLevel(y: 4, x: 5));

  expect(true, Class.constructor(x: 4).value);
  expect(false, Class.constructor(y: 4, x: 5).value);

  expect(true, Class().instanceMethod(x: 4));
  expect(false, Class().instanceMethod(y: 4, x: 5));

  expect(true, Class.staticMethod(x: 4));
  expect(false, Class.staticMethod(y: 4, x: 5));

  expect(true, Enum.a.value);
  expect(false, Enum.b.value);

  expect(true, Enum.a.instanceMethod(x: 4));
  expect(false, Enum.a.instanceMethod(y: 4, x: 5));

  expect(true, Enum.staticMethod(x: 4));
  expect(false, Enum.staticMethod(y: 4, x: 5));

  expect(true, MixinApplication().instanceMethod(x: 4));
  expect(false, MixinApplication().instanceMethod(y: 4, x: 5));

  expect(true, Mixin.staticMethod(x: 4));
  expect(false, Mixin.staticMethod(y: 4, x: 5));

  expect(true, false.instanceMethod(x: 4));
  expect(false, false.instanceMethod(y: 4, x: 5));

  expect(true, Extension.staticMethod(x: 4));
  expect(false, Extension.staticMethod(y: 4, x: 5));

  expect(true, ExtensionType.constructor(x: 4).value);
  expect(false, ExtensionType.constructor(y: 4, x: 5).value);

  expect(true, ExtensionType(false).instanceMethod(x: 4));
  expect(false, ExtensionType(false).instanceMethod(y: 4, x: 5));

  expect(true, ExtensionType.staticMethod(x: 4));
  expect(false, ExtensionType.staticMethod(y: 4, x: 5));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}