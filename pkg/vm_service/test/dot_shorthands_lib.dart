// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=dot-shorthands
// @dart = 3.10

import 'dart:developer';
import 'common/test_helper.dart';

class C {
  int value;
  C(this.value); // LINE_A

  static C two = C(2);
  static C get three => C(3); // LINE_B
  static C four() => C(4); // LINE_C
}

void testeeMain() {
  C c = C(1);
  debugger();
  // ignore: experiment_not_enabled
  c = .two; // LINE_D
  // ignore: experiment_not_enabled
  c = .three; // LINE_E
  // ignore: experiment_not_enabled
  c = .four(); // LINE_F
  print(c.value);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeMain);
}
