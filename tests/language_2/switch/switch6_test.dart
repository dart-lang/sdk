// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// The break is in the right scope, http://b/3428700 was agreed upon.

import "package:expect/expect.dart";

class Switch6Test {
  static testMain() {
    var a = 0;
    var x = -1;
    switch (a) {
      case 0:
        {
          x = 0;
          break;
        }
      case 1:
        x = 1;
        break;
    }
    Expect.equals(0, x);
  }
}

main() {
  Switch6Test.testMain();
}
