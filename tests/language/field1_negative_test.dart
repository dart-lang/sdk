// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test to catch error reporting bugs in class fields declarations.
// Should be an error because we have setter/getter functions and fields
// in the class.

class C {
  var a;

  get a {
    return 1;
  }

  set a(int val) {
    var x = val;
  }

  get b {
    return 2;
  }

  set b(int val) {
    var x = val;
  }
}

class Field1NegativeTest {
  static testMain() {
    var c = new C();
  }
}

main() {
  Field1NegativeTest.testMain();
}
