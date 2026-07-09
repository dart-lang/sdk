// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'common/expect.dart';
import 'common/test_helper.dart';

num Function() testFunction() {
  debugger(); // LINE_A
  late int a;
  try {
    late int b;
    try {
      for (final int i = 0; i < 10;) {
        // ignore: prefer_function_declarations_over_variables
        int x() => i + a + b;
        return x; // LINE_B
      }
    } finally {
      b = 10; // LINE_C
    }
  } finally {
    a = 1; // LINE_D
  }
  throw StateError('Unreachable');
}

void testMain() {
  final f = testFunction();
  Expect.equals(f(), 11);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
