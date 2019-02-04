// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug --async_debugger

import 'dart:developer';
import 'package:observatory/models.dart' as M;
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

const LINE_C = 21;
const LINE_A = 27;
const LINE_B = 33;
const LINE_D = 28;

foobar() async {
  await null;
  debugger();
  print('foobar'); // LINE_C.
}

helper() async {
  await null;
  debugger();
  print('helper'); // LINE_A.
  await foobar(); // LINE_D
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
    // No awaiter frames because we are in a completely synchronous stack.
    expect(stack['awaiterFrames'], isNull);
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  (Isolate isolate) async {
    // Verify awaiter stack trace is the current frame + the awaiter.
    ServiceMap stack = await isolate.getStack();
    expect(stack['awaiterFrames'], isNotNull);
    List awaiterFrames = stack['awaiterFrames'];

    expect(awaiterFrames.length, greaterThanOrEqualTo(4));
    // Awaiter frame.
    expect(await awaiterFrames[0].toUserString(),
        stringContainsInOrder(['foobar', '.dart:$LINE_C']));
    // Awaiter frame.
    expect(await awaiterFrames[1].toUserString(),
        stringContainsInOrder(['helper', '.dart:$LINE_D']));
    // Suspension point.
    expect(awaiterFrames[2].kind, equals(M.FrameKind.asyncSuspensionMarker));
    // Causal frame.
    expect(await awaiterFrames[3].toUserString(),
        stringContainsInOrder(['testMain', '.dart:$LINE_B']));
  },
];

main(args) =>
    runIsolateTestsSynchronous(args, tests, testeeConcurrent: testMain);
