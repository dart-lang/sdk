// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to test arithmetic operations.

import "package:expect/expect.dart";

class B {}

class C {
  B call(B b) => b;
}

typedef B BToB(B x);

C c = null;

void check(BToB f) {
  Expect.isNull(f);
}

main() {
  // The implicit tear-off of `.call` should be tolerant of `null`.
  check(c); // Equivalent to `check(c?.call);`
}
