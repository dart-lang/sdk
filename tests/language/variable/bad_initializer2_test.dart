// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Variable initializer must not reference the initialized variable.
import "package:expect/expect.dart";

main() {
  var foo = (int n) {
    if (n == 0) {
      return 0;
    } else {
      return 1
          + foo(n - 1)
          //^^^
          // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
          // [cfe] Local variable 'foo' can't be referenced before it is declared.
          // [cfe] Method not found: 'foo'.
          ;
    }
  };
  foo(1);
//^
// [cfe] Method not found: 'foo'.
}
