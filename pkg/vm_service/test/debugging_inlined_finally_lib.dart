// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'common/expect.dart';
import 'common/test_helper.dart';

enum ExitFlow {
  Outer,
  InnerTrue,
  InnerFalse,
}

num Function() testFunction({required ExitFlow exitFlow}) {
  late int a;
  try {
    late int b;
    if (exitFlow == ExitFlow.Outer) {
      int z() => 20 + a;
      return z; // LINE_F
    }
    try {
      for (final int i = 0; i < 10;) {
        // ignore: prefer_function_declarations_over_variables
        int x() => i + a + b;
        // ignore: prefer_function_declarations_over_variables
        int y() => throw 'throw requested!';
        if (exitFlow == ExitFlow.InnerTrue) {
          return y; // LINE_E
        } else {
          return x; // LINE_B
        }
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
  debugger(); // LINE_A
  final f = testFunction(exitFlow: ExitFlow.InnerFalse);
  Expect.equals(f(), 11);
  final g = testFunction(exitFlow: ExitFlow.InnerTrue);
  Expect.throws(() => g());
  final h = testFunction(exitFlow: ExitFlow.Outer);
  Expect.equals(h(), 21);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
