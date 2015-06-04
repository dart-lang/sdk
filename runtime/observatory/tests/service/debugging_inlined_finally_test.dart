// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--compile-all --error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'dart:async';
import 'dart:developer';

testFunction() {
  debugger();
  var a;
  try {
    var b;
    try {
      for (int i = 0; i < 10; i++) {
        var x = () => i + a + b;
        return x;  // line 20
      }
    } finally {
      b = 10;  // line 23
    }
  } finally {
    a = 1;  // line 26
  }
}

testMain() {
  var f = testFunction();
  expect(f(), equals(11));
}

var tests = [

hasStoppedAtBreakpoint,

// Add breakpoint
(Isolate isolate) async {
  await isolate.rootLibrary.load();

  var script = isolate.rootLibrary.scripts[0];
  await script.load();

  // Add 3 breakpoints.
  {
    var result = await isolate.addBreakpoint(script, 20);
    expect(result is Breakpoint, isTrue);
    Breakpoint bpt = result;
    expect(bpt.type, equals('Breakpoint'));
    expect(bpt.location.script.id, equals(script.id));
    expect(bpt.location.script.tokenToLine(bpt.location.tokenPos), equals(20));
    expect(isolate.breakpoints.length, equals(1));
  }

  {
    var result = await isolate.addBreakpoint(script, 23);
    expect(result is Breakpoint, isTrue);
    Breakpoint bpt = result;
    expect(bpt.type, equals('Breakpoint'));
    expect(bpt.location.script.id, equals(script.id));
    expect(bpt.location.script.tokenToLine(bpt.location.tokenPos), equals(23));
    expect(isolate.breakpoints.length, equals(2));
  }

  {
    var result = await isolate.addBreakpoint(script, 26);
    expect(result is Breakpoint, isTrue);
    Breakpoint bpt = result;
    expect(bpt.type, equals('Breakpoint'));
    expect(bpt.location.script.id, equals(script.id));
    expect(bpt.location.script.tokenToLine(bpt.location.tokenPos), equals(26));
    expect(isolate.breakpoints.length, equals(3));
  }

  // Wait for breakpoint events.
},

resumeIsolate,

hasStoppedAtBreakpoint,

// We are at the breakpoint on line 20.
(Isolate isolate) async {
  ServiceMap stack = await isolate.getStack();
  expect(stack.type, equals('Stack'));
  expect(stack['frames'].length, greaterThanOrEqualTo(1));

  Script script = stack['frames'][0].location.script;
  expect(script.tokenToLine(stack['frames'][0].location.tokenPos), equals(20));
},

resumeIsolate,

hasStoppedAtBreakpoint,

// We are at the breakpoint on line 23.
(Isolate isolate) async {
  ServiceMap stack = await isolate.getStack();
  expect(stack.type, equals('Stack'));
  expect(stack['frames'].length, greaterThanOrEqualTo(1));

  Script script = stack['frames'][0].location.script;
  expect(script.tokenToLine(stack['frames'][0].location.tokenPos), equals(23));
},

resumeIsolate,

hasStoppedAtBreakpoint,

// We are at the breakpoint on line 26.
(Isolate isolate) async {
  ServiceMap stack = await isolate.getStack();
  expect(stack.type, equals('Stack'));
  expect(stack['frames'].length, greaterThanOrEqualTo(1));

  Script script = stack['frames'][0].location.script;
  expect(script.tokenToLine(stack['frames'][0].location.tokenPos), equals(26));
},

resumeIsolate,

];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
