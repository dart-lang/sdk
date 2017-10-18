// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js. Test that the argument to an unresolved static
// getter is only evaluated once.

import "package:expect/expect.dart";

int i = 0;

p(x) => i++;

class A {}

main() {
  bool caught = false;
  try {
    A.unknown = p(2); /*@compile-error=unspecified*/
  } catch (_) {
    caught = true;
  }
  Expect.isTrue(caught);
  Expect.equals(1, i);
}
