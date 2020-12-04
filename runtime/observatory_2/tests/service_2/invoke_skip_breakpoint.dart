// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

const int LINE_A = 21;
const int LINE_B = 16;

bar() {
  print('bar');
  return 'bar';
}

testMain() {
  debugger();
  bar();
  print("Done");
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  setBreakpointAtLine(LINE_B),
  (Isolate isolate) async {
    Library lib = isolate.rootLibrary;
    await lib.load();

    dynamic result = await isolate.invokeRpc("invoke", {
      "targetId": lib.id,
      "selector": "bar",
      "argumentIds": [],
      "disableBreakpoints": true
    });
    print(result);
    expect(result.valueAsString, equals('bar'));
  },
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  resumeIsolate,
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
