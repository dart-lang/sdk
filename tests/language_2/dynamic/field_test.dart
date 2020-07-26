// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test that ensures that fields can be accessed dynamically.

import "package:expect/expect.dart";

class A extends C {
  var a;
  var b;
}

class C {
  foo() {
    print(a);
    //    ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
    // [cfe] The getter 'a' isn't defined for the class 'C'.
    return a;
    //     ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
    // [cfe] The getter 'a' isn't defined for the class 'C'.
  }
  bar() {
    print(b.a);
    //    ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
    // [cfe] The getter 'b' isn't defined for the class 'C'.
    return b.a;
    //     ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
    // [cfe] The getter 'b' isn't defined for the class 'C'.
  }
}

main() {
  var a = new A();
  a.a = 1;
  a.b = a;
  Expect.equals(1, a.foo());
  Expect.equals(1, a.bar());
}
