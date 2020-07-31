// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that compiler doesn't crash while inlining recognized method
// when receiver is a dead code.
// Regression test for https://github.com/dart-lang/sdk/issues/42065.

import "package:expect/expect.dart";

List<int> foo0(int par1) {
  if (par1 >= 39) {
    return <int>[];
  }
  throw 'hi';
}

main() {
  Expect.throws(() {
    (foo0(0)).add(42);
  }, (e) => e == 'hi');
}
