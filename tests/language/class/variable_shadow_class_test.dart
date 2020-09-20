// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import "package:expect/expect.dart";

// Local variables can shadow class names.

class Test {
  final int field;
  Test.named(this.field);
}

main() {
  {
    var Test;
    // Now this refers to the variable.
    var i = new Test.named(10);
    //          ^^^^
    // [analyzer] COMPILE_TIME_ERROR.PREFIX_SHADOWED_BY_LOCAL_DECLARATION
    // [cfe] Method not found: 'Test.named'.
    Expect.equals(10, i.field);
  }

  {
    // Shadowing is allowed.
    var Test = 1;
    Expect.equals(2, Test + 1);
  }
}
