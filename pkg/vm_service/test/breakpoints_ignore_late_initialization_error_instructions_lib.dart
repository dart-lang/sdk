// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

int getThree() => 3;

void testeeMain() {
  // ignore: prefer_final_locals
  late int x = 1;
  final double xd =
      // When a late variable is read, the VM performs checks to ensure that the
      // variable has been initialized. When a breakpoint is set on the
      // following line, it should resolve to the [toDouble] call instruction,
      // not to an instruction part of the late variable initialization checks.
      x.toDouble(); // LINE_A
  print(xd);

  late final int y = 2;
  final double yd =
      // When a late final variable is read, the VM performs checks to ensure
      // that the variable has been assigned a value exactly once. When a
      // breakpoint is set on the following line, it should resolve to the
      // [toDouble] call instruction, not to an instruction part of the late
      // variable assignment checks.
      y.toDouble(); // LINE_B
  print(yd);

  late final int z;
  // When a late final variable is assigned a value, the VM performs checks to
  // ensure that the variable has not already been initialized. When a
  // breakpoint is set on the following line, it should resolve on the '='
  // token, not to an instruction part of the late variable initialization
  // checks.
  z = getThree(); // LINE_C
  print(z);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeMain);
}
