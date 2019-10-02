// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that debugger can stop on an unhandled exception thrown from async
// function. Regression test for https://dartbug.com/38697.

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'service_test_common.dart';

const LINE_A = 16;

throwException() async {
  throw 'exception'; // LINE_A
}

testeeMain() async {
  try {
    await throwException();
  } finally {}
}

var tests = <IsolateTest>[
  hasStoppedWithUnhandledException,
  stoppedAtLine(LINE_A),
  (Isolate isolate) async {
    print("Stopped!");
    var stack = await isolate.getStack();
    expect(stack['frames'][0].function.toString(), contains('throwException'));
  }
];

main(args) => runIsolateTests(args, tests,
    pause_on_unhandled_exceptions: true, testeeConcurrent: testeeMain);
