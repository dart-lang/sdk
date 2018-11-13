// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug --async_debugger

import 'dart:developer';
import 'package:observatory/models.dart' as M;
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

const LINE_A = 27;
const LINE_B = 33;
const LINE_C = 37;

notCalled() async {
  await null;
  await null;
  await null;
  await null;
}

foobar() async {
  await null;
  debugger();
  print('foobar'); // LINE_A.
}

helper() async {
  await null;
  print('helper');
  await foobar(); // LINE_B.
}

testMain() {
  helper(); // LINE_C.
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  (Isolate isolate) async {
    // Verify awaiter stack trace is the current frame + the awaiter.
    ServiceMap stack = await isolate.getStack();
    expect(stack['awaiterFrames'], isNotNull);
    List awaiterFrames = stack['awaiterFrames'];
    expect(awaiterFrames.length, greaterThanOrEqualTo(4));
    // Awaiter frame.
    expect(await awaiterFrames[0].toUserString(),
        stringContainsInOrder(['foobar', '.dart:${LINE_A}']));
    // Awaiter frame.
    expect(await awaiterFrames[1].toUserString(),
        stringContainsInOrder(['helper', '.dart:${LINE_B}']));
    // Suspension point.
    expect(awaiterFrames[2].kind, equals(M.FrameKind.asyncSuspensionMarker));
    // Causal frame.
    expect(await awaiterFrames[3].toUserString(),
        stringContainsInOrder(['testMain', '.dart:${LINE_C}']));
  },
];

main(args) =>
    runIsolateTestsSynchronous(args, tests, testeeConcurrent: testMain);
