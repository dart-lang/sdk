// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--optimization-counter-threshold=10 --no-background-compilation
//
// Test that SpeculativeInt64ShiftOp's range is correctly inferred when the RHS
// is a nullable smi.

import 'package:expect/expect.dart';

int? getShift(List<String> args) {
  return args.length == -1 ? null : 40;
}

void test(List<String> args) {
  dynamic x = 1;
  if (args.length <= 0) {
    int? s = getShift(args);
    x = x << s;
  }
  x += 1;
  Expect.equals(x, 1099511627777);
}

void main(List<String> args) {
  for (int i = 0; i < 100; ++i) {
    test(args);
  }
}
