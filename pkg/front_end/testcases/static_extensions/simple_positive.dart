// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  static String get foo => "A.foo";
}

extension E on A {
  static String get foo => "E.foo";
  static String get bar => "E.bar";
}

main() {
  expectEqual(A.foo, "A.foo");
  expectEqual(A.bar, "E.bar");
}

expectEqual(a, b) {
  if (a != b) {
    throw "Expected the values to be equal.";
  }
}
