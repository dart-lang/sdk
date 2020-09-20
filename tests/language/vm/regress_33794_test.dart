// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that sub-expressions with side-effects are handled correctly
// in the presence of exceptions or deoptimization.

import "package:expect/expect.dart";

int var1 = -35;

main() {
  try {
    var1 = (((~(var1)) ^ (++var1)) >> (++var1));
  } catch (e) {
    Expect.equals('Invalid argument(s): -33', e.toString());
  } finally {
    Expect.equals(-33, var1);
  }
}
