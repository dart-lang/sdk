// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type A(Object? it) {
  static String get extensionTypeGetter => "A.extensionTypeGetter";
  static void set extensionTypeSetter(num value) {
    throw "A.extensionTypeSetter=";
  }

  static String extensionTypeMethod() => "A.extensionTypeMethod";
}

extension E on A {
  static String get extensionTypeGetter => "E.extensionTypeGetter";
  static String get extensionGetter => "E.extensionGetter";
  static void set extensionTypeSetter(num value) {}
  static void set extensionSetter(bool value) {}
  static String extensionTypeMethod() => "E.extensionTypeMethod";
  static String extensionMethod() => "E.extensionMethod";
}

main() {
  expectEqual(A.extensionTypeGetter, "A.extensionTypeGetter");
  expectEqual(A.extensionGetter, "E.extensionGetter");
  expectThrows(() {
    A.extensionTypeSetter = 0;
  });
  expectDoesntThrow(() {
    A.extensionSetter = false;
  });
  expectEqual(A.extensionTypeMethod(), "A.extensionTypeMethod");
  expectEqual(A.extensionMethod(), "E.extensionMethod");
}

expectEqual(a, b) {
  if (a != b) {
    throw "Expected the values to be equal.";
  }
}

expectThrows(Function() f) {
  bool hasThrown = false;
  try {
    f();
  } on dynamic {
    hasThrown = true;
  }
  if (!hasThrown) {
    throw "Expected the function to throw an exception.";
  }
}

expectDoesntThrow(Function() f) {
  bool hasThrown = true;
  try {
    f();
    hasThrown = false;
  } on dynamic {}
  if (hasThrown) {
    throw "Expected the function not to throw exceptions.";
  }
}
