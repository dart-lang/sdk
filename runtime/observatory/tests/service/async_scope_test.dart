// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--compile_all --error_on_bad_type --error_on_bad_override

import 'dart:async';
import 'dart:developer';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

foo() {}

doAsync(param1) async {
  var local1 = param1 + 1;
  foo(); // Line 16
  await null;
}

doAsyncStar(param2) async* {
  var local2 = param2 + 1;
  foo(); // Line 22
  yield null;
}

testeeDo() {
  debugger();

  doAsync(1).then((_) {
    doAsyncStar(1).listen((_) {});
  });
}


checkAsyncVarDescriptors(Isolate isolate) async {
  ServiceMap stack = await isolate.getStack();
  expect(stack.type, equals('Stack'));
  expect(stack['frames'].length, greaterThanOrEqualTo(1));
  Frame frame = stack['frames'][0];
  var vars = frame.variables.map((v) => v['name']).join(' ');
  expect(vars, equals('param1 local1')); // no :async_op et al
}


checkAsyncStarVarDescriptors(Isolate isolate) async {
  ServiceMap stack = await isolate.getStack();
  expect(stack.type, equals('Stack'));
  expect(stack['frames'].length, greaterThanOrEqualTo(1));
  Frame frame = stack['frames'][0];
  var vars = frame.variables.map((v) => v['name']).join(' ');
  expect(vars, equals('param2 local2')); // no :async_op et al
}


var tests = [
  hasStoppedAtBreakpoint, // debugger()
  setBreakpointAtLine(16),
  setBreakpointAtLine(22),
  resumeIsolate,

  hasStoppedAtBreakpoint,
  stoppedAtLine(16),
  checkAsyncVarDescriptors,
  resumeIsolate,

  hasStoppedAtBreakpoint,
  stoppedAtLine(22),
  checkAsyncStarVarDescriptors,
  resumeIsolate,
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testeeDo);
