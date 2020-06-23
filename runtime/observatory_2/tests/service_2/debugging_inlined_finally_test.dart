// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';
import 'dart:developer';

const int LINE_A = 23;
const int LINE_B = 26;
const int LINE_C = 29;

testFunction() {
  debugger();
  var a;
  try {
    var b;
    try {
      for (int i = 0; i < 10; i++) {
        var x = () => i + a + b;
        return x; // LINE_A
      }
    } finally {
      b = 10; // LINE_B
    }
  } finally {
    a = 1; // LINE_C
  }
}

testMain() {
  var f = testFunction();
  expect(f(), equals(11));
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,

// Add breakpoint
  (Isolate isolate) async {
    await isolate.rootLibrary.load();

    var script = isolate.rootLibrary.scripts[0];
    await script.load();

    // Add 3 breakpoints.
    {
      var result = await isolate.addBreakpoint(script, LINE_A);
      expect(result is Breakpoint, isTrue);
      Breakpoint bpt = result;
      expect(bpt.type, equals('Breakpoint'));
      expect(bpt.location.script.id, equals(script.id));
      expect(bpt.location.script.tokenToLine(bpt.location.tokenPos),
          equals(LINE_A));
      expect(isolate.breakpoints.length, equals(1));
    }

    {
      var result = await isolate.addBreakpoint(script, LINE_B);
      expect(result is Breakpoint, isTrue);
      Breakpoint bpt = result;
      expect(bpt.type, equals('Breakpoint'));
      expect(bpt.location.script.id, equals(script.id));
      expect(bpt.location.script.tokenToLine(bpt.location.tokenPos),
          equals(LINE_B));
      expect(isolate.breakpoints.length, equals(2));
    }

    {
      var result = await isolate.addBreakpoint(script, LINE_C);
      expect(result is Breakpoint, isTrue);
      Breakpoint bpt = result;
      expect(bpt.type, equals('Breakpoint'));
      expect(bpt.location.script.id, equals(script.id));
      expect(bpt.location.script.tokenToLine(bpt.location.tokenPos),
          equals(LINE_C));
      expect(isolate.breakpoints.length, equals(3));
    }

    // Wait for breakpoint events.
  },

  resumeIsolate,

  hasStoppedAtBreakpoint,

// We are at the breakpoint on line LINE_A.
  (Isolate isolate) async {
    ServiceMap stack = await isolate.getStack();
    expect(stack.type, equals('Stack'));
    expect(stack['frames'].length, greaterThanOrEqualTo(1));

    Script script = stack['frames'][0].location.script;
    expect(script.tokenToLine(stack['frames'][0].location.tokenPos),
        equals(LINE_A));
  },

  resumeIsolate,

  hasStoppedAtBreakpoint,

// We are at the breakpoint on line LINE_B.
  (Isolate isolate) async {
    ServiceMap stack = await isolate.getStack();
    expect(stack.type, equals('Stack'));
    expect(stack['frames'].length, greaterThanOrEqualTo(1));

    Script script = stack['frames'][0].location.script;
    expect(script.tokenToLine(stack['frames'][0].location.tokenPos),
        equals(LINE_B));
  },

  resumeIsolate,

  hasStoppedAtBreakpoint,

// We are at the breakpoint on line LINE_C.
  (Isolate isolate) async {
    ServiceMap stack = await isolate.getStack();
    expect(stack.type, equals('Stack'));
    expect(stack['frames'].length, greaterThanOrEqualTo(1));

    Script script = stack['frames'][0].location.script;
    expect(script.tokenToLine(stack['frames'][0].location.tokenPos),
        equals(LINE_C));
  },

  resumeIsolate,
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
