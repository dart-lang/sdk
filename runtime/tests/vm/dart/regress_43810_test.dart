// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that intrinsic Float64List.[]= works even if parameters are
// unboxed.
// Regression test for https://github.com/dart-lang/sdk/issues/43810.

import 'dart:typed_data';
import 'package:expect/expect.dart';

main() {
  final list1 = <double>[
    1, 2, 3, 4,
  ];
  var list = new Float64List(list1.length);
  list.setRange(0, list1.length, list1);
  Expect.equals(1.0, list[0]);
  Expect.equals(2.0, list[1]);
  Expect.equals(3.0, list[2]);
  Expect.equals(4.0, list[3]);
}
