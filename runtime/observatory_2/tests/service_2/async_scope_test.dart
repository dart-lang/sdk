// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

const int LINE_A = 20;
const int LINE_B = 26;

foo() {}

doAsync(param1) async {
  var local1 = param1 + 1;
  foo(); // Line A.
  await local1;
}

doAsyncStar(param2) async* {
  var local2 = param2 + 1;
  foo(); // Line B.
  yield local2;
}

testeeDo() {
  debugger();

  doAsync(1).then((_) {
    doAsyncStar(1).listen((_) {});
  });
}

Future checkAsyncVarDescriptors(Isolate isolate) async {
  ServiceMap stack = await isolate.getStack();
  expect(stack.type, equals('Stack'));
  expect(stack['frames'].length, greaterThanOrEqualTo(1));
  Frame frame = stack['frames'][0];
  var vars = frame.variables.map((v) => v['name']).join(' ');
  expect(vars, equals('param1 local1')); // no :async_op et al
}

Future checkAsyncStarVarDescriptors(Isolate isolate) async {
  ServiceMap stack = await isolate.getStack();
  expect(stack.type, equals('Stack'));
  expect(stack['frames'].length, greaterThanOrEqualTo(1));
  Frame frame = stack['frames'][0];
  var vars = frame.variables.map((v) => v['name']).join(' ');
  expect(vars, equals('param2 local2')); // no :async_op et al
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint, // debugger()
  setBreakpointAtLine(LINE_A),
  setBreakpointAtLine(LINE_B),
  resumeIsolate,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  checkAsyncVarDescriptors,
  resumeIsolate,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  checkAsyncStarVarDescriptors,
  resumeIsolate,
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testeeDo);
