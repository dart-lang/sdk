// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const LINE_A = 13;
const LINE_B = 14;

Future<String> testFunction(String caption) async {
  await Future.delayed(Duration(milliseconds: 1)); // LINE_A
  return caption; // LINE_B
}

Future<void> testMain() async {
  debugger();
  final str = await testFunction('The caption');
  print(str);
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  setBreakpointAtLine(LINE_A),
  setBreakpointAtLine(LINE_B),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  hasLocalVarInTopStackFrame('caption'),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  hasLocalVarInTopStackFrame('caption'),
  hasLocalVarInTopStackFrame('caption'),
  resumeIsolate,
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'local_variable_in_awaiter_async_frame_test.dart',
      testeeConcurrent: testMain,
    );
