// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--deterministic

import "package:expect/expect.dart";

import 'dart:typed_data';

// Found by DartFuzzing: inconsistent view of unboxing
// https://github.com/dart-lang/sdk/issues/37821

double var5 = 0.5521203015696288;

class X0 {
  double fld0_1 = 0.44794902547497595;
  void run() {
    for (int loc1 = 0; loc1 < 11; loc1++) {
      var5 = fld0_1;
    }
    fld0_1 -= 20;
  }
}

class X1 extends X0 {
  void run() {
    super.run();
  }
}

@pragma("vm:never-inline")
void checkMe(double value) {
  Expect.approxEquals(0.44794902547497595, value);
}

main() {
  Expect.approxEquals(0.5521203015696288, var5);
  new X1().run();
  checkMe(var5);
}
