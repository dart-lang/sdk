// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 22822. The assignment in the finally block
// used to crash because it was executed at context level 1 instead of
// context level 2.

import 'package:expect/expect.dart';

test(b) {
  try {
    for (int i = 0; i < 10; i++) {
      // Closurizing i and b, thus the return statement
      // executes at context level 2, and the code in
      // the finally block runs at context level 1.
      return () => i + b;
    }
  } finally {
    b = 10;
  }
}

main() {
  var c = test(0);
  Expect.equals(10, c());
}
