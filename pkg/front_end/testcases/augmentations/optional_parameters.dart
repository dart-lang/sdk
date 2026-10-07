// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

bool topLevel([int x, int y]);
augment bool topLevel([int x = 6, int y = 5]) => x < y;

class Class {
  final bool value;

  new () : value = false;

  new constructor([int x, int y]);
  augment new constructor([int x = 6, int y = 5]) : value = x < y;

  bool instanceMethod([int x, int y]);
  augment bool instanceMethod([int x = 6, int y = 5]) => x < y;

  static bool staticMethod([int x, int y]);
  augment static bool staticMethod([int x = 6, int y = 5]) => x < y;
}

enum Enum {
  a.constructor(4),
  b.constructor(5, 4),
  ;

  final bool value;

  new constructor([int x, int y]);
  augment new constructor([int x = 6, int y = 5]) : value = x < y;

  bool instanceMethod([int x, int y]);
  augment bool instanceMethod([int x = 6, int y = 5]) => x < y;

  static bool staticMethod([int x, int y]);
  augment static bool staticMethod([int x = 6, int y = 5]) => x < y;
}

mixin Mixin {
  bool instanceMethod([int x, int y]);
  augment bool instanceMethod([int x = 6, int y = 5]) => x < y;

  static bool staticMethod([int x, int y]);
  augment static bool staticMethod([int x = 6, int y = 5]) => x < y;
}

class MixinApplication = Object with Mixin;

extension Extension on bool {
  bool instanceMethod([int x, int y]);
  augment bool instanceMethod([int x = 6, int y = 5]) => x < y;

  static bool staticMethod([int x, int y]);
  augment static bool staticMethod([int x = 6, int y = 5]) => x < y;
}

extension type ExtensionType(bool value) {
  new constructor([int x, int y]);
  augment new constructor([int x = 6, int y = 5]) : this(x < y);

  bool instanceMethod([int x, int y]);
  augment bool instanceMethod([int x = 6, int y = 5]) => x < y;

  static bool staticMethod([int x, int y]);
  augment static bool staticMethod([int x = 6, int y = 5]) => x < y;
}

main() {
  expect(true, topLevel(4));
  expect(false, topLevel(5, 4));

  expect(true, Class.constructor(4).value);
  expect(false, Class.constructor(5, 4).value);

  expect(true, Class().instanceMethod(4));
  expect(false, Class().instanceMethod(5, 4));

  expect(true, Class.staticMethod(4));
  expect(false, Class.staticMethod(5, 4));

  expect(true, Enum.a.value);
  expect(false, Enum.b.value);

  expect(true, Enum.a.instanceMethod(4));
  expect(false, Enum.a.instanceMethod(5, 4));

  expect(true, Enum.staticMethod(4));
  expect(false, Enum.staticMethod(5, 4));

  expect(true, MixinApplication().instanceMethod(4));
  expect(false, MixinApplication().instanceMethod(5, 4));

  expect(true, Mixin.staticMethod(4));
  expect(false, Mixin.staticMethod(5, 4));

  expect(true, false.instanceMethod(4));
  expect(false, false.instanceMethod(5, 4));

  expect(true, Extension.staticMethod(4));
  expect(false, Extension.staticMethod(5, 4));

  expect(true, ExtensionType.constructor(4).value);
  expect(false, ExtensionType.constructor(5, 4).value);

  expect(true, ExtensionType(false).instanceMethod(4));
  expect(false, ExtensionType(false).instanceMethod(5, 4));

  expect(true, ExtensionType.staticMethod(4));
  expect(false, ExtensionType.staticMethod(5, 4));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}