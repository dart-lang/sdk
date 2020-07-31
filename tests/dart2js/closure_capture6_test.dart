// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Simple test for free variable in two nested scopes.

captureTwiceNested(x) {
  // 'x' value captured at two levels.
  return () => [x, () => x + 1];
}

main() {
  var a = captureTwiceNested(1);
  Expect.equals(1, a()[0]);
  Expect.equals(2, a()[1]());
}
