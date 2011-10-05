// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing the prohibited use of a variable before it has
// been declared, which is not trivial to detect in the context of a variable
// declaration shadowing another one.

class ScopeNegativeTest {
  static testMain() {
    var a = 1;
    {
      var b = 2;
      var c = a;  // Use of 'a' prior to its shadow declaration below.
      var d = b + c;
      var a = 5;  // Shadow declaration of 'a'.
      return d + a;
    }
  }
}


main() {
  ScopeNegativeTest.testMain();
}
