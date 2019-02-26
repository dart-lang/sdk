// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization_counter_threshold=10 --no-background-compilation --shared-slow-path-triggers-gc
// VMOptions=--optimization_counter_threshold=10 --no-background-compilation --shared-slow-path-triggers-gc --no-use-vfp

// This tests the stackmaps and environments for safepoints corresponding to
// slow-path code which uses shared runtime stubs.

import 'package:expect/expect.dart';
import 'dart:math';

class C {
  C talk(C _) => _;
}

int getPositiveNum() {
  return (new DateTime.now()).millisecondsSinceEpoch;
}

C getC() {
  if (getPositiveNum() == 0) {
    return new C();
  } else {
    return null;
  }
}

int global;

int getNum() {
  return global++;
}

test0(int k) {
  var x = getC();
  var y = getNum();
  try {
    y = getNum();
    x = getC();
    x.talk(x).talk(x);
    y = getNum();
  } catch (e) {
    Expect.equals(x, null);
    Expect.equals(y, k);
  }
}

test1(int k) {
  var x = getC();
  var y = getNum();
  double z = getPositiveNum().toDouble();
  while (z > 1) {
    z = sqrt(z - 0.1);
  }
  try {
    y = getNum();
    x = getC();
    z = z.ceil().toDouble();
    var k = z / 2;
    x.talk(x).talk(x);
    z = k / 2;
    y = getNum();
  } catch (e) {
    Expect.equals(x, null);
    Expect.equals(y, k);
    Expect.equals(z, 1);
  }
}

main() {
  global = 1;

  for (int i = 0; i < 100; ++i) {
    test0(2 * (i + 1));
  }

  global = 1;

  for (int i = 0; i < 100; ++i) {
    test1(2 * (i + 1));
  }
}
