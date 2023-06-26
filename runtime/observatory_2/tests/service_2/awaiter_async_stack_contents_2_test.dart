// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
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

const LINE_A = 30;
const LINE_B = 36;
const LINE_C = 40;

const LINE_0 = 29;

notCalled() async {
  await null;
  await null;
  await null;
  await null;
}

foobar() async {
  await null;
  debugger(); // LINE_0.
  print('foobar'); // LINE_A.
}

helper() async {
  await null;
  print('helper');
  await foobar(); // LINE_B.
}

testMain() async {
  helper(); // LINE_C.
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_0),
  stepOver,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  (Isolate isolate) async {
    // Verify awaiter stack trace is the current frame + the awaiter.
    ServiceMap stack = await isolate.getStack();
    expect(stack['asyncCausalFrames'], isNotNull);
    List<Frame> asyncCausalFrames = (stack['asyncCausalFrames'] as List).cast();
    for (final v in asyncCausalFrames) {
      print(v);
    }

    expect(asyncCausalFrames.length, greaterThanOrEqualTo(4));
    expect(await asyncCausalFrames[0].toUserString(),
        stringContainsInOrder(['foobar', '.dart:${LINE_A}']));
    expect(asyncCausalFrames[1].kind, M.FrameKind.asyncSuspensionMarker);
    expect(await asyncCausalFrames[2].toUserString(),
        stringContainsInOrder(['helper', '.dart:${LINE_B}']));
    expect(asyncCausalFrames[3].kind, M.FrameKind.asyncSuspensionMarker);
  },
];

main(args) => runIsolateTestsSynchronous(args, tests,
    testeeConcurrent: testMain, extraArgs: extraDebuggingArgs);
