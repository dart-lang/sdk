// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'common/test_helper.dart';

class C {
  int instVar = 1;

  void method() {
    // The closure does not use `this`, so the receiver is not available when
    // paused inside it.
    // ignore: avoid_function_literals_in_foreach_calls
    [6].forEach((innerParam) {
      final innerTemp = 7;
      debugger(); // LINE_A
      print(innerParam + innerTemp);
    });
  }
}

void testMain() {
  C().method();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
