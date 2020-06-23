// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

// This test was mostly interesting for DBC, which needed to patch two bytecodes
// to create a breakpoint for fast Smi ops.

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';
import 'dart:developer';

const int LINE_A = 26;
const int LINE_B = 27;
const int LINE_C = 28;

class NotGeneric {}

testeeMain() {
  var x = new List(1);
  var y = 7;
  debugger();
  print("Statement");
  x[0] = 3; // Line A.
  x is NotGeneric; // Line B.
  y & 4; // Line C.
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,

// Add breakpoints.
  (Isolate isolate) async {
    Library rootLib = await isolate.rootLibrary.load();
    var script = rootLib.scripts[0];

    var bpt1 = await isolate.addBreakpoint(script, LINE_A);
    print(bpt1);
    expect(bpt1.resolved, isTrue);
    expect(await bpt1.location.getLine(), equals(LINE_A));

    var bpt2 = await isolate.addBreakpoint(script, LINE_B);
    print(bpt2);
    expect(bpt2.resolved, isTrue);
    expect(await bpt2.location.getLine(), equals(LINE_B));

    var bpt3 = await isolate.addBreakpoint(script, LINE_C);
    print(bpt3);
    expect(bpt3.resolved, isTrue);
    expect(await bpt3.location.getLine(), equals(LINE_C));
  },

  resumeIsolate,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  resumeIsolate,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  resumeIsolate,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  resumeIsolate,
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testeeMain);
