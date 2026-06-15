// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

Future<void> foo() async {}

Future<void> doAsync(stop) async {
  // Flutter issue 18877:
  // If a closure is defined in the context of an async method, stepping over
  // an await causes the implicit breakpoint to be set for that closure instead
  // of the async_op, resulting in the debugger falling through.
  // ignore: prefer_function_declarations_over_variables
  final baz = () => print('doAsync($stop) done!');
  if (stop) debugger(); // LINE_D
  await foo(); // LINE_A
  await foo(); // LINE_B
  await foo(); // LINE_C
  baz();
}

void testMain() {
  // With two runs of doAsync floating around, async step should only cause
  // us to stop in the run we started in.
  doAsync(false);
  doAsync(true);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
