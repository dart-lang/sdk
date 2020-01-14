// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that a condition is only evaluated once in a loop.

main() {
  int c = 0;
  do {
    c++;
  } while (c++ < 2);
  Expect.equals(4, c);
}
