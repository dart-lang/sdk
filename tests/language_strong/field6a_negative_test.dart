// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test to catch error reporting bugs in class fields declarations.
// Should be an error because we have a function overriding a getter.

class A {
  int get a {
    return 10;
  }

  int a() {
    return 1;
  }
}

class Field6aNegativeTest {
  static testMain() {
    var a = new A();
  }
}

main() {
  Field6aNegativeTest.testMain();
}
