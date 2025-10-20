// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  static String get classGetter => "A.classGetter";
  static void set classSetter(num value) {
    throw "A.classSetter=";
  }
  static String classMethod() => "A.classMethod";
}

extension E on A {
  static String get classGetter => "E.classGetter";
  static String get extensionGetter => "E.extensionGetter";
  static void set classSetter(num value) {}
  static void set extensionSetter(bool value) {}
  static String classMethod() => "E.classMethod";
  static String extensionMethod() => "E.extensionMethod";
}

main() {
  expectEqual(A.classGetter, "A.classGetter");
  expectEqual(A.extensionGetter, "E.extensionGetter");
  expectThrows(() { A.classSetter = 0; });
  expectDoesntThrow(() { A.extensionSetter = false; });
  expectEqual(A.classMethod(), "A.classMethod");
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
