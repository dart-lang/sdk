// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Issue #37408: AOT did not throw.

import "package:expect/expect.dart";

import 'dart:math';

String var0 = '5Zso';

double foo2(String par1) {
  return atan2(0.16964141699241508, num.tryParse('\u2665vDil'));
}

class X0 {
  void run() {
    foo2(var0);
  }
}

main() {
  bool x = false;
  try {
    new X0().run();
  } catch (exception, stackTrace) {
    x = true;
  }
  Expect.isTrue(x);
}
