// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test integer division by zero.
// Test that results before and after optimization are the same.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation

import "package:expect/expect.dart";

divBy0(a) => a ~/ 0;

main() {
  Expect.throws(() => divBy0(4), (e) => e is IntegerDivisionByZeroException);
}
