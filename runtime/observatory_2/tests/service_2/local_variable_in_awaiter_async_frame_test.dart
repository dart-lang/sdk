// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

const int LINE_A = 14;

Future<String> testFunction(String caption) async {
  await Future.delayed(Duration(milliseconds: 1));
  return caption;
}

testMain() async {
  debugger();
  var str = await testFunction('The caption');
  print(str);
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  setBreakpointAtLine(LINE_A),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  hasLocalVarInTopAwaiterStackFrame('caption'),
  resumeIsolate,
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
