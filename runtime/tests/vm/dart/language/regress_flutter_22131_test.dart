// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that inferred type of a final field takes constant objects into
// account. This is a regression test for
// https://github.com/flutter/flutter/issues/22131.

// VMOptions=--no_background_compilation --optimization_counter_threshold=10

import "package:expect/expect.dart";

class X {
  final Map<int, String> data;
  const X(this.data);
}

const f = X({1: "ok-f"});
final g = X({1: "ok-g"});

void doTest() {
  Expect.equals("ok-f", f.data[1]);
  Expect.equals("ok-g", g.data[1]);
}

void main() {
  for (int i = 0; i < 20; i++) {
    doTest();
  }
}
