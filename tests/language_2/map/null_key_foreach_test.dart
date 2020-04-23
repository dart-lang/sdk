// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Regression test for using `null` as a key with `forEach`.

main() {
  var x = new Map<int, int>();
  x[1] = 2;
  x[null] = 1;
  int c = 0;
  x.forEach((int i, int j) {
    c++;
    Expect.isTrue(i == null || i is int, 'int or null expected');
  });
  Expect.equals(2, c);
}
