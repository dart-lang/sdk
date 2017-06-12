// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for capturing.

import "package:expect/expect.dart";

// Regression test for issue 5991015.

class V {
  notCalled(Function x) {
    return x();
  }

  foofoo(x) {
    return x;
  }

  hoop(input, n) {
    while (n-- > 0) {
      Expect.equals(5, input);
      continue; // This continue statement must properly unchain the context.
      switch (input) {
        case 3:
          var values = foofoo;
          notCalled(() => values(input));
      }
    }
  }
}

main() {
  new V().hoop(5, 3);
}
