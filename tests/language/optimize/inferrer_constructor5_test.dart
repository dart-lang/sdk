// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  A() {
    print(field + 42);
    //    ^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
    // [cfe] The getter 'field' isn't defined for the class 'A'.
  }
}

class B extends A {
  var field;
  B() {
    field = 42;
  }
}

main() {
  Expect.throwsNoSuchMethodError(() => new B());
}
