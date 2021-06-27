// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'package:expect/expect.dart';

// Regression test for mis-optimized (a / b).runtimeType.

void main() {
  Type t0;
  Type t1;
  for (int i = 0; i < 2; i++) {
    t0 = i.runtimeType;
    t1 = ((i * 2) / 2).runtimeType;
  }
  final t2 = ((0 * 2) / 2).runtimeType;

  Expect.equals('int', '$t0');
  Expect.equals('int', '$t1');
  Expect.equals('int', '$t2');
}
