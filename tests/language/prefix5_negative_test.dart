// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library Prefix5NegativeTest.dart;

import "package:expect/expect.dart";
import "library10.dart";

class Prefix5NegativeTest {
  static Test1() {
    // Library prefixes in the imported libraries should not be visible here.
    var result = 0;
    result += lib11.Library11.static_func();
    Expect.equals(6, result);
    result += lib11.Library11.static_fld;
    Expect.equals(10, result);
  }
}

main() {
  Prefix5NegativeTest.Test1();
}
