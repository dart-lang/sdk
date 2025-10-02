// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  static String get foo => "A.foo";
  static void set baz(num value) {
    throw "A.baz=";
  }
}

extension E on A {
  static String get foo => "E.foo";
  static String get bar => "E.bar";
  static void set baz(num value) {}
  static void set quux(bool value) {}
}

main() {
  expectEqual(A.foo, "A.foo");
  expectEqual(A.bar, "E.bar");
  expectThrows(() { A.baz = 0; });
  expectDoesntThrow(() { A.quux = false; });
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
