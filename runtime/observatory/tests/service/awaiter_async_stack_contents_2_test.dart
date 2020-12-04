// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--async-debugger --verbose-debug --lazy-async-stacks

import 'dart:developer';
import 'package:observatory/models.dart' as M;
import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

const LINE_A = 28;
const LINE_B = 34;
const LINE_C = 38;

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

testMain() async {
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
    for (final v in awaiterFrames) {
      print(v);
    }

    expect(awaiterFrames.length, greaterThanOrEqualTo(2));
    // Awaiter frame.
    expect(await awaiterFrames[0].toUserString(),
        stringContainsInOrder(['foobar', '.dart:${LINE_A}']));
    // Awaiter frame.
    expect(await awaiterFrames[1].toUserString(),
        stringContainsInOrder(['helper', '.dart:${LINE_B}']));
  },
];

main(args) => runIsolateTestsSynchronous(args, tests,
    testeeConcurrent: testMain, extraArgs: extraDebuggingArgs);
