// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

var d;

test(a) {
  while (true) {
    try {
      var b;
      try {
        for (int i = 0; i < 10; i++) {
          // Closurizing i, a, and b, thus the return statement
          // executes at context level 3, and the code in
          // the finally blocks runs at context level 1 and 2.
          return () => i + a + b;
        }
      } finally {
        b = 10;
        while (true) {
          // Chain a new context.
          var c = 5;
          d = () => a + b + c;
          break;
        }
      }
    } finally {
      a = 1;
    }
    break;
  }
}

main() {
  var c = test(0);
  Expect.equals(11, c());
  Expect.equals(16, d());
}
