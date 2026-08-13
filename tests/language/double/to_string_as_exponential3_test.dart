// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test basic integer operations.

import "package:expect/expect.dart";

main() {
  Expect.equals("1.00000000000000000000e+0", (1.0).toStringAsExponential(20));
  Expect.equals("1.00000000000000005551e-1", (0.1).toStringAsExponential(20));
  Expect.equals(1.00000000000000005551e-1, 0.1);
}
