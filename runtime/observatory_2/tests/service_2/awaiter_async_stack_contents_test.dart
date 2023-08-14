// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--async-debugger --verbose-debug

import 'dart:developer';
import 'package:observatory_2/service_io.dart';
import 'package:observatory_2/models.dart' as M;
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

const LINE_C = 26;
const LINE_A = 32;
const LINE_B = 38;
const LINE_D = 33;

const LINE_0 = 25;
const LINE_1 = 31;
const LINE_2 = 37;

foobar() async {
  await null;
  debugger(); // LINE_0.
  print('foobar'); // LINE_C.
}

helper() async {
  await null;
  debugger(); // LINE_1.
  print('helper'); // LINE_A.
  await foobar(); // LINE_D.
}

testMain() {
  debugger(); // LINE_2.
  helper(); // LINE_B.
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_2),
  stepOver,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  (Isolate isolate) async {
    ServiceMap stack = await isolate.getStack();
    // No asynchronous frames because we are in a completely synchronous stack.
    expect(stack['asyncCausalFrames'], isNull);
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_1),
  stepOver,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_0),
  stepOver,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  (Isolate isolate) async {
    // Verify awaiter stack trace is the current frame + the awaiter.
    ServiceMap stack = await isolate.getStack();
    expect(stack['asyncCausalFrames'], isNotNull);
    List<Frame> asyncCausalFrames = (stack['asyncCausalFrames'] as List).cast();

    expect(asyncCausalFrames.length, greaterThanOrEqualTo(4));
    expect(await asyncCausalFrames[0].toUserString(),
        stringContainsInOrder(['foobar', '.dart:$LINE_C']));
    expect(asyncCausalFrames[1].kind, M.FrameKind.asyncSuspensionMarker);
    expect(await asyncCausalFrames[2].toUserString(),
        stringContainsInOrder(['helper', '.dart:$LINE_D']));
    expect(asyncCausalFrames[3].kind, M.FrameKind.asyncSuspensionMarker);
    // "helper" is not await'ed.
  },
];

main(args) => runIsolateTestsSynchronous(args, tests,
    testeeConcurrent: testMain, extraArgs: extraDebuggingArgs);
