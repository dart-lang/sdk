// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// This program tripped dart2js.

foo(bool b) {
  var x = 499;
  // If the loop-phi is not declared it will assign to a global and the
  // recursive call will screw up the methods "local" state.
  for (int i = 0; i < 3; i++) {
    if (i == 0 && b) x = 42;
    if (!b) foo(true);
  }
  return x;
}

main() {
  Expect.equals(499, foo(false));
}
