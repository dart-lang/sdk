// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'dart:developer';
import 'package:observatory/models.dart' as M;
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

const LINE_A = 28;
const LINE_B = 20;
const LINE_C = 22;

foobar() async* {
  await 0; // force async gap
  debugger();
  yield 1; // LINE_B.
  debugger();
  yield 2; // LINE_C.
}

helper() async {
  await 0; // force async gap
  debugger();
  print('helper'); // LINE_A.
  await for (var i in foobar()) {
    print('helper $i');
  }
}

testMain() {
  helper();
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  (Isolate isolate) async {
    ServiceMap stack = await isolate.getStack();
    // No causal frames because we are in a completely synchronous stack.
    expect(stack['asyncCausalFrames'], isNotNull);
    var asyncStack = stack['asyncCausalFrames'];
    expect(asyncStack[0].toString(), contains('helper'));
    expect(asyncStack[1].kind, equals(M.FrameKind.asyncSuspensionMarker));
    expect(asyncStack[2].toString(), contains('testMain'));
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  (Isolate isolate) async {
    ServiceMap stack = await isolate.getStack();
    // Has causal frames (we are inside an async function)
    expect(stack['asyncCausalFrames'], isNotNull);
    var asyncStack = stack['asyncCausalFrames'];
    expect(asyncStack[0].toString(), contains('foobar'));
    expect(asyncStack[1].kind, equals(M.FrameKind.asyncSuspensionMarker));
    expect(asyncStack[2].toString(), contains('helper'));
    expect(asyncStack[3].kind, equals(M.FrameKind.asyncSuspensionMarker));
    expect(asyncStack[4].toString(), contains('testMain'));
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  (Isolate isolate) async {
    ServiceMap stack = await isolate.getStack();
    // Has causal frames (we are inside a function called by an async function)
    expect(stack['asyncCausalFrames'], isNotNull);
    var asyncStack = stack['asyncCausalFrames'];
    print('async:');
    await printFrames(asyncStack);
    print('sync:');
    await printFrames(stack['frames']);
    expect(asyncStack[0].toString(), contains('foobar'));
    expect(asyncStack[1].kind, equals(M.FrameKind.asyncSuspensionMarker));
    expect(asyncStack[2].toString(), contains('helper'));
    expect(asyncStack[3].kind, equals(M.FrameKind.asyncSuspensionMarker));
    expect(asyncStack[4].toString(), contains('testMain'));
    // Line 22.
    expect(
        await asyncStack[0].location.toUserString(), contains('.dart:$LINE_C'));
    // Line 29.
    expect(await asyncStack[2].location.toUserString(), contains('.dart:29'));
    // Line 35.
    expect(await asyncStack[4].location.toUserString(), contains('.dart:35'));
  },
];

main(args) =>
    runIsolateTestsSynchronous(args, tests, testeeConcurrent: testMain);
