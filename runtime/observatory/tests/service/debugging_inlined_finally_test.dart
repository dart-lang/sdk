// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'dart:developer';

testFunction() {
  debugger();
  var a;
  try {
    var b;
    try {
      for (int i = 0; i < 10; i++) {
        var x = () => i + a + b;
        return x;  // line 19
      }
    } finally {
      b = 10;  // line 22
    }
  } finally {
    a = 1;  // line 25
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
    var result = await isolate.addBreakpoint(script, 19);
    expect(result is Breakpoint, isTrue);
    Breakpoint bpt = result;
    expect(bpt.type, equals('Breakpoint'));
    expect(bpt.location.script.id, equals(script.id));
    expect(bpt.location.script.tokenToLine(bpt.location.tokenPos), equals(19));
    expect(isolate.breakpoints.length, equals(1));
  }

  {
    var result = await isolate.addBreakpoint(script, 22);
    expect(result is Breakpoint, isTrue);
    Breakpoint bpt = result;
    expect(bpt.type, equals('Breakpoint'));
    expect(bpt.location.script.id, equals(script.id));
    expect(bpt.location.script.tokenToLine(bpt.location.tokenPos), equals(22));
    expect(isolate.breakpoints.length, equals(2));
  }

  {
    var result = await isolate.addBreakpoint(script, 25);
    expect(result is Breakpoint, isTrue);
    Breakpoint bpt = result;
    expect(bpt.type, equals('Breakpoint'));
    expect(bpt.location.script.id, equals(script.id));
    expect(bpt.location.script.tokenToLine(bpt.location.tokenPos), equals(25));
    expect(isolate.breakpoints.length, equals(3));
  }

  // Wait for breakpoint events.
},

resumeIsolate,

hasStoppedAtBreakpoint,

// We are at the breakpoint on line 19.
(Isolate isolate) async {
  ServiceMap stack = await isolate.getStack();
  expect(stack.type, equals('Stack'));
  expect(stack['frames'].length, greaterThanOrEqualTo(1));

  Script script = stack['frames'][0].location.script;
  expect(script.tokenToLine(stack['frames'][0].location.tokenPos), equals(19));
},

resumeIsolate,

hasStoppedAtBreakpoint,

// We are at the breakpoint on line 22.
(Isolate isolate) async {
  ServiceMap stack = await isolate.getStack();
  expect(stack.type, equals('Stack'));
  expect(stack['frames'].length, greaterThanOrEqualTo(1));

  Script script = stack['frames'][0].location.script;
  expect(script.tokenToLine(stack['frames'][0].location.tokenPos), equals(22));
},

resumeIsolate,

hasStoppedAtBreakpoint,

// We are at the breakpoint on line 25.
(Isolate isolate) async {
  ServiceMap stack = await isolate.getStack();
  expect(stack.type, equals('Stack'));
  expect(stack['frames'].length, greaterThanOrEqualTo(1));

  Script script = stack['frames'][0].location.script;
  expect(script.tokenToLine(stack['frames'][0].location.tokenPos), equals(25));
},

resumeIsolate,

];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
