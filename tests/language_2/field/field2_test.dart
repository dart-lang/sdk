// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test to catch error reporting bugs in class fields declarations.
// Should be an error because we have setter/getter functions and fields
// in the class.

// @dart = 2.9

class C {
  get a {
    return 1;
  }

  set a(int val) {
  //  ^
  // [cfe] Conflicts with the implicit setter of the field 'a'.
    var x = val;
  }

  get b {
    return 2;
  }

  set b(int val) {
    var x = val;
  }

  var a;
  //  ^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [cfe] 'a' is already declared in this scope.
  // [cfe] Conflicts with setter 'a'.
}

class Field2Test {
  static testMain() {
    var c = new C();
  }
}

main() {
  Field2Test.testMain();
}
