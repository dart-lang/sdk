// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Regression test for issue 17149.

int globalCounter = 0;

void nonInlinedUse(Object object) {
  if (new DateTime.now().millisecondsSinceEpoch == 42) nonInlinedUse(object);
  if (object is! String) globalCounter++;
}

int confuse(x) {
  if (new DateTime.now().millisecondsSinceEpoch == 42) return confuse(x - 1);
  return x;
}

main() {
  var o = ["foo", 499][confuse(1)];

  // The `o is String` check in the rhs of the logical or must not be
  // propagated to the `if` body.
  if ((o is num) || (o is String && true)) {
    nonInlinedUse(o);
  }
  Expect.equals(1, globalCounter);
}
