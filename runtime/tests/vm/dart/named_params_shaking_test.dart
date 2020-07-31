// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test that optimization of named parameters doesn't change evaluation order.

import 'dart:math';
import 'package:expect/expect.dart';

int global = 0;

int inc() => ++global;
int dec() => global = max(0, --global);

// When converting named parameters to positional parameters, we
// follow alphabetical order. Ensure that argument evaluation order
// is unchanged.
void testNamedOrder(int w, {int? z, int? y, int? x}) {
  Expect.equals(w, 1);
  Expect.equals(z, 2);
  Expect.equals(y, 3);
  Expect.equals(x, 2);
}

class TestNamedOrderBase {
  TestNamedOrderBase(w, {int? z, int? y, int? x}) {
    testNamedOrder(w, z: z, y: y, x: x);
  }
}

class TestNamedOrderSub extends TestNamedOrderBase {
  int x;
  TestNamedOrderSub()
      : x = dec(),
        super(inc(), z: inc(), y: inc(), x: dec()) {
    Expect.equals(x, 0);
  }
}

main() {
  testNamedOrder(inc(), z: inc(), y: inc(), x: dec());
  global = 1;
  TestNamedOrderSub();
}
