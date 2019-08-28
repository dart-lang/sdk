// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--deterministic

import "package:expect/expect.dart";

import 'dart:typed_data';

// Found by "value-guided" DartFuzzing: incorrect clamping.
// https://github.com/dart-lang/sdk/issues/37868
@pragma("vm:never-inline")
foo(List<int> x) => Uint8ClampedList.fromList(x);

main() {
  var x = [
    9223372036854775807,
    -9223372036854775808,
    9223372032559808513,
    -9223372032559808513,
    5000000000,
    -5000000000,
    2147483647,
    -2147483648,
    255,
    -255,
  ];
  var y = foo(x);
  for (int i = 0; i < y.length; i += 2) {
    Expect.equals(255, y[i]);
    Expect.equals(0, y[i + 1]);
  }
}
