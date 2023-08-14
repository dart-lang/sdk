// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that no errors are generated if a wildcard pattern appears inside a
// pattern assignment.

import "package:expect/expect.dart";

void bareUnderscore() {
  var x;
  [x, _] = [0, 1];
  Expect.equals(0, x);
}

main() {
  bareUnderscore();
}
