// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization_counter_threshold=10 --deterministic
// Requirements=nnbd-strong

// Verifies that null cannot be casted to Object.
// Regression test for https://github.com/dart-lang/sdk/issues/41272.

import 'package:expect/expect.dart';

doTest() {
  dynamic x;
  Expect.throwsTypeError(() {
    x as Object;
  });
}

main() {
  for (int i = 0; i < 20; ++i) {
    doTest();
  }
}
