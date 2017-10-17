// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test basic integer operations.

import "package:expect/expect.dart";

main() {
  var v = 0.0;
  Expect.throwsRangeError(() => v.toStringAsFixed(-1));
  Expect.throwsRangeError(() => v.toStringAsFixed(21));
  Expect.throwsArgumentError(() => v.toStringAsFixed(null));
  v.toStringAsFixed(1.5);//# 01: compile-time error
  v.toStringAsFixed("string");//# 02: compile-time error
  v.toStringAsFixed("3");//# 03: compile-time error
}
