// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Regression test which checks that shift left with constant operand compiles
// correctly even if narrowed to Int32 shift.

import 'dart:typed_data';

import 'package:expect/expect.dart';

const int N = 10;

@pragma('vm:never-inline')
void test(Int32List v) {
  // The shape of the code here is choosen to trigger Int64->Int32
  // narrowing in the range analysis.
  v[0] = (v[0] & 0xFF) << (N - 1);
}

void main() {
  final list = Int32List(1);
  for (var i = 0; i < 10; i++) {
    list[0] = i;
    test(list);
    Expect.equals(i << 9, list[0]);
  }
}
