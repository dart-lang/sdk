// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';
import 'dart:developer';

const int LINE_A = 13;

Future<String> testFunction() async {
  await new Future.delayed(new Duration(milliseconds: 1));
  return "Done";
}

testMain() async {
  debugger();
  var str = await testFunction();
  print(str);
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,

// Add breakpoint at the entry of async function
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
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
