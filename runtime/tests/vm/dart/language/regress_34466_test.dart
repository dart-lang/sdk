// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test NaN comparison (dartbug.com/34466 and dartbug.com/34467).

// VMOptions=--no_background_compilation --optimization_counter_threshold=10

import "package:expect/expect.dart";

double dvar = double.nan;

int doit() {
  if (!(((-84).toDouble() <= double.nan))) {
    return 1;
  } else {
    return 2;
  }
}

doTests() {
  Expect.isFalse(dvar > dvar);
  Expect.isFalse(dvar < dvar);
  Expect.isFalse(dvar <= dvar);
  Expect.isFalse(dvar >= dvar);
  Expect.isFalse(dvar > -dvar);
  Expect.isFalse(-dvar > dvar);

  Expect.isTrue(!(dvar > dvar));
  Expect.isTrue(!(dvar < dvar));
  Expect.isTrue(!(dvar <= dvar));
  Expect.isTrue(!(dvar >= dvar));
  Expect.isTrue(!(dvar > -dvar));
  Expect.isTrue(!(-dvar > dvar));

  Expect.equals(1, doit());

  Expect.isFalse(dvar == dvar);
  Expect.isFalse(dvar == -dvar);
  Expect.isTrue(dvar != dvar);
  Expect.isTrue(dvar != -dvar);

  Expect.isTrue(!(dvar == dvar));
  Expect.isTrue(!(dvar == -dvar));
  Expect.isFalse(!(dvar != dvar));
  Expect.isFalse(!(dvar != -dvar));
}

void main() {
  for (int i = 0; i < 20; ++i) {
    doTests();
  }
}
