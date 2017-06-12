// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override  --verbose_debug --async_debugger

import 'dart:developer';
import 'package:observatory/models.dart' as M;
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

const LINE_C = 19;
const LINE_A = 24;
const LINE_B = 30;

foobar() async {
  debugger();
  print('foobar'); // LINE_C.
}

helper() async {
  debugger();
  print('helper'); // LINE_A.
  await foobar();
}

testMain() {
  debugger();
  helper(); // LINE_B.
}

var tests = [
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
        stringContainsInOrder(['foobar', '.dart:19']));
    // Awaiter frame.
    expect(await awaiterFrames[1].toUserString(),
        stringContainsInOrder(['helper', '.dart:25']));
    // Suspension point.
    expect(awaiterFrames[2].kind, equals(M.FrameKind.asyncSuspensionMarker));
    // Causal frame.
    expect(await awaiterFrames[3].toUserString(),
        stringContainsInOrder(['testMain', '.dart:30']));
  },
];

main(args) =>
    runIsolateTestsSynchronous(args, tests, testeeConcurrent: testMain);
