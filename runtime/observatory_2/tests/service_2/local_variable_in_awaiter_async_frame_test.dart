// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'service_test_common.dart';
import 'test_helper.dart';

const int LINE_A = 13;
const int LINE_B = 14;

Future<String> testFunction(String caption) async {
  await Future.delayed(Duration(milliseconds: 1)); // LINE_A
  return caption; // LINE_B
}

testMain() async {
  debugger();
  var str = await testFunction('The caption');
  print(str);
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  setBreakpointAtLine(LINE_A),
  setBreakpointAtLine(LINE_B),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  hasLocalVarInTopStackFrame('caption', 'frames'),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  hasLocalVarInTopStackFrame('caption', 'asyncCausalFrames'),
  hasLocalVarInTopStackFrame('caption', 'frames'),
  resumeIsolate,
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
