// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test to catch error reporting bugs in class fields declarations.
// Should be an error because we have a function overriding a setter name.

class A {
  void set a(var val) {
    int i = val;
  }
  int a() {
    return 1;
  }
}

class Field7aNegativeTest {
  static testMain() {
  }
}

main() {
  Field7aNegativeTest.testMain();
}
