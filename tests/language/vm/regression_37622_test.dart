// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--deterministic

// Issue #37622 found with fuzzing: internal compiler crash (division-by-zero).

import 'dart:typed_data';

import "package:expect/expect.dart";

@pragma('vm:never-inline')
int foo() {
  int x = 0;
  {
    int loc0 = 67;
    while (--loc0 > 0) {
      --loc0;
      x += (4 ~/ (Int32x4.wxwx >> loc0));
      --loc0;
      --loc0;
    }
  }
  return -1;
}

main() {
  int x = 0;
  bool d = false;
  try {
    x = foo();
  } on IntegerDivisionByZeroException catch (e) {
    d = true;
  }
  Expect.equals(x, 0);
  Expect.isTrue(d);
}
