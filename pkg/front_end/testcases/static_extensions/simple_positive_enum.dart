// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum A {
  element;

  static String get enumGetter => "A.enumGetter";
  static void set enumSetter(num value) {
    throw "A.enumSetter=";
  }

  static String enumMethod() => "A.enumMethod";
}

extension E on A {
  static String get enumGetter => "E.enumGetter";
  static String get extensionGetter => "E.extensionGetter";
  static void set enumSetter(num value) {}
  static void set extensionSetter(bool value) {}
  static String enumMethod() => "E.enumMethod";
  static String extensionMethod() => "E.extensionMethod";
}

main() {
  expectEqual(A.enumGetter, "A.enumGetter");
  expectEqual(A.extensionGetter, "E.extensionGetter");
  expectThrows(() {
    A.enumSetter = 0;
  });
  expectDoesntThrow(() {
    A.extensionSetter = false;
  });
  expectEqual(A.enumMethod(), "A.enumMethod");
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
