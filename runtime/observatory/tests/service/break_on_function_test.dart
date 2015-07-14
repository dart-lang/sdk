// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--compile_all --error_on_bad_type --error_on_bad_override  --verbose_debug

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'dart:developer';

testFunction(flag) {  // Line 11
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

var tests = [

hasStoppedAtBreakpoint,

// Add breakpoint
(Isolate isolate) async {
  var rootLib = await isolate.rootLibrary.load();
  var function = rootLib.functions.singleWhere((f) => f.name == 'testFunction');

  var bpt = await isolate.addBreakpointAtEntry(function);
  expect(bpt is Breakpoint, isTrue);
  print(bpt);
},

resumeIsolate,

hasStoppedAtBreakpoint,

// We are at the breakpoint on line 11.
(Isolate isolate) async {
  ServiceMap stack = await isolate.getStack();
  expect(stack.type, equals('Stack'));
  expect(stack['frames'].length, greaterThanOrEqualTo(1));

  Script script = stack['frames'][0].location.script;
  expect(stack['frames'][0].location.tokenPos, equals(22));
},

resumeIsolate,

hasStoppedAtBreakpoint,

// We are at the breakpoint on line 11.
(Isolate isolate) async {
  ServiceMap stack = await isolate.getStack();
  expect(stack.type, equals('Stack'));
  expect(stack['frames'].length, greaterThanOrEqualTo(1));

  Script script = stack['frames'][0].location.script;
  expect(stack['frames'][0].location.tokenPos, equals(22));
},

resumeIsolate,

];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
