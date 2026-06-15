// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: prefer_function_declarations_over_variables

import 'dart:developer';

import 'common/test_helper.dart';

void testParameters(int jjjj, int oooo, [int? hhhh, int? nnnn]) {
  debugger(); // LINE_A
}

void testMain() {
  // ignore: unused_local_variable
  int? xxx, yyyy, zzzzz;
  for (int i = 0; i < 1; i++) {
    // ignore: unused_local_variable
    final foo = () {};
    debugger(); // LINE_B
  }
  void bar() {
    print(xxx);
    print(yyyy);
    debugger(); // LINE_C
  }

  bar();
  testParameters(0, 0);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
