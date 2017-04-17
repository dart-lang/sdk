// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

library Prefix4NegativeTest.dart;

import "package:expect/expect.dart";
import "library10.dart";

class Prefix4NegativeTest {
  static Test1() {
    // Library prefixes in the imported libraries should not be visible here.
    var result = 0;
    var obj = new lib11.Library11(1);
    result = obj.fld;
    Expect.equals(1, result);
    result += obj.func();
    Expect.equals(3, result);
  }
}

main() {
  Prefix4NegativeTest.Test1();
}
