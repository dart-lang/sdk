// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test basic integer operations.

import "package:expect/expect.dart";

main() {
  var v = 1.0;
  Expect.throwsRangeError(() => v.toStringAsExponential(-1));
  Expect.throwsRangeError(() => v.toStringAsExponential(21));
  v.toStringAsExponential(1.5); //# 01: compile-time error
  v.toStringAsExponential("string"); //# 02: compile-time error
  v.toStringAsExponential("3"); //# 03: compile-time error
}
