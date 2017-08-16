// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart2js failed when a declared function was captured inside itself.

foo(f) => f(499);

main() {
  fun(x) {
    if (x < 3) {
      return foo((x) => fun(x));
    } else {
      return x;
    }
  }

  Expect.equals(499, fun(499));
}
