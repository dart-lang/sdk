// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization_counter_threshold=10 --deterministic

// Regression test for https://github.com/dart-lang/sdk/issues/39905.
//
// Verifies that OSR when calculating arguments of string interpolation
// doesn't crash optimizer.

import "package:expect/expect.dart";

main() {
  Expect.equals(
      'x[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19]',
      'x${[for (int i = 0; i < 20; ++i) i]}');
}
