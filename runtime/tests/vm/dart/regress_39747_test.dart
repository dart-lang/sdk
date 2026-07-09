// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/39747.
// Verifies that compiler doesn't crash on a particular piece of code.

import "package:expect/expect.dart";

dynamic foo4() => null;

var par1 = 1.0.toStringAsPrecision(12);

void doTest() {
  for (int i = 0; i < 10; ++i) {
    // foo4() returns constant null.
    // foo4().toStringAsPrecision(-37) is a PolymorphicInstanceCall with
    // a single target _Double.toStringAsPrecision.
    // Type propagation narrows down receiver type and assigns type _Double to
    // subsequent uses of null constant.
    (foo4().toStringAsPrecision(-37));
    // Add a Phi which uses double constant and null.
    // Unboxed representation is selected for this Phi, causing
    // Unbox instruction for null constant which can deoptimize.
    (par1 != null ? 11.11 : foo4());
  }
}

main() {
  Expect.throws(() => doTest());
}
