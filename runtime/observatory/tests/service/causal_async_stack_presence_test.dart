// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--lazy-async-stacks --verbose_debug

import 'dart:developer';
import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

const LINE_C = 19;
const LINE_A = 24;
const LINE_B = 30;

foobar() {
  debugger();
  print('foobar'); // LINE_C.
}

helper() async {
  debugger();
  print('helper'); // LINE_A.
  foobar();
}

testMain() {
  debugger();
  helper(); // LINE_B.
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  (Isolate isolate) async {
    ServiceMap stack = await isolate.getStack();
    // No causal frames because we are in a completely synchronous stack.
    expect(stack['asyncCausalFrames'], isNull);
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  (Isolate isolate) async {
    ServiceMap stack = await isolate.getStack();
    // Has causal frames (we are inside an async function)
    expect(stack['asyncCausalFrames'], isNotNull);
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  (Isolate isolate) async {
    ServiceMap stack = await isolate.getStack();
    // Has causal frames (we are inside a function called by an async function)
    expect(stack['asyncCausalFrames'], isNotNull);
  },
];

main(args) => runIsolateTestsSynchronous(args, tests,
    testeeConcurrent: testMain, extraArgs: extraDebuggingArgs);
