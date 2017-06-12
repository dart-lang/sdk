// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that a NoSuchMethodError is thrown even when an expression
// seems to be free of side-effects.

test(x, y) {
  (() {
    x - y;
  })();
}

main() {
  Expect.throws(() {
    test(null, 2);
  }, (e) => e is NoSuchMethodError);
}
