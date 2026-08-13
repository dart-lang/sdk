// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dartbug.com/36953: check that phi is inserted correctly
// when try block has no normal exit.

// VMOptions=--optimization_counter_threshold=10 --deterministic

import "package:expect/expect.dart";

void testBody() {
  var v;
  do {
    try {} catch (e, st) {
      continue;
    }

    try {
      v = 10;
      throw "";
    } catch (e, st) {}
  } while (v++ < 10);
  Expect.equals(11, v);
}

void main() {
  testBody();
  testBody();
}
