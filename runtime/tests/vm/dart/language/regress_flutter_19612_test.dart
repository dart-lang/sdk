// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/flutter/flutter/issues/19612.
// This test verifies that negated condition is correctly handled by the
// AOT compiler.

import "package:expect/expect.dart";

class X {
  final int? maxLines;
  X([this.maxLines]);

  bool get isMultiline => maxLines != 1;
}

X x1 = new X(1);
X x2 = new X(42);
X x3 = new X();

main() {
  Expect.isFalse(x1.isMultiline);
  Expect.isTrue(x2.isMultiline);
  Expect.isTrue(x3.isMultiline);
}
