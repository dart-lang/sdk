// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override  --verbose_debug

import 'dart:developer';
import 'package:observatory/models.dart' as M;
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
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
    var asyncStack = stack['asyncCausalFrames'];
    expect(asyncStack[0].toString(), contains('helper'));
    expect(asyncStack[1].kind, equals(M.FrameKind.asyncSuspensionMarker));
    expect(asyncStack[2].toString(), contains('testMain'));
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  (Isolate isolate) async {
    ServiceMap stack = await isolate.getStack();
    // Has causal frames (we are inside a function called by an async function)
    expect(stack['asyncCausalFrames'], isNotNull);
    var asyncStack = stack['asyncCausalFrames'];
    expect(asyncStack[0].toString(), contains('foobar'));
    expect(asyncStack[1].toString(), contains('helper'));
    expect(asyncStack[2].kind, equals(M.FrameKind.asyncSuspensionMarker));
    expect(asyncStack[3].toString(), contains('testMain'));
    // Line 19.
    expect(await asyncStack[0].location.toUserString(), contains('.dart:19'));
    // Line 25.
    expect(await asyncStack[1].location.toUserString(), contains('.dart:25'));
    // Line 30.
    expect(await asyncStack[3].location.toUserString(), contains('.dart:30'));
  },
];

main(args) =>
    runIsolateTestsSynchronous(args, tests, testeeConcurrent: testMain);
