// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that debugger can stop on an unhandled exception thrown from async
// function. Regression test for https://dartbug.com/38697.

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';
import 'service_test_common.dart';

const LINE_A = 18;
const LINE_B = 23;
const LINE_C = 26;

throwException() async {
  throw 'exception'; // LINE_A
}

testeeMain() async {
  try {
    await throwException(); // LINE_B
  } finally {
    try {
      await throwException(); // LINE_C
    } finally {}
  }
}

var tests = <IsolateTest>[
  hasStoppedWithUnhandledException,
  stoppedAtLine(LINE_A),
  (Isolate isolate) async {
    print("Stopped!");
    var stack = await isolate.getStack();
    expect(stack['frames'][0].function.toString(), contains('throwException'));
  },
  resumeIsolate,
  hasStoppedWithUnhandledException,
  (Isolate isolate) async {
    var stack = await isolate.getStack();
    print(stack['frames'][0]);
    // await in testeeMain
    expect(await stack['frames'][0].location.toUserString(),
        contains('.dart:${LINE_B}'));
  },
  resumeIsolate,
  hasStoppedWithUnhandledException,
  stoppedAtLine(LINE_A),
  resumeIsolate,
  hasStoppedWithUnhandledException,
  (Isolate isolate) async {
    var stack = await isolate.getStack();
    print(stack['frames'][0]);
    expect(await stack['frames'][0].location.toUserString(),
        contains('.dart:${LINE_C}'));
  }
];

main(args) => runIsolateTests(args, tests,
    pause_on_unhandled_exceptions: true, testeeConcurrent: testeeMain);
