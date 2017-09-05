// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Evaluation of an if-null expression e of the form e1 ?? e2 is equivalent to
// the evaluation of the expression ((x) => x == null ? e2 : x)(e1).
//
// Therefore, e1 should be evaluated first; if it is non-null, e2 should not
// be evaluated.

import "package:expect/expect.dart";

void bad() {
  throw new Exception();
}

bool firstExecuted = false;

first() {
  firstExecuted = true;
  return null;
}

second() {
  Expect.isTrue(firstExecuted);
  return 2;
}

main() {
  Expect.equals(1, 1 ?? bad());
  Expect.equals(2, first() ?? second());
}
