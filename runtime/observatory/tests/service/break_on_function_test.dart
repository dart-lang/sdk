// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';
import 'dart:developer';

const int LINE_A = 14;

testFunction(flag) {
  // Line A.
  if (flag) {
    print("Yes");
  } else {
    print("No");
  }
}

testMain() {
  debugger();
  testFunction(true);
  testFunction(false);
  print("Done");
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,

// Add breakpoint
  (Isolate isolate) async {
    Library rootLib = await isolate.rootLibrary.load() as Library;
    var function =
        rootLib.functions.singleWhere((f) => f.name == 'testFunction');

    var bpt = await isolate.addBreakpointAtEntry(function);
    expect(bpt is Breakpoint, isTrue);
    print(bpt);
  },

  resumeIsolate,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  resumeIsolate,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  resumeIsolate,
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
