// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'dart:developer';

import 'package:test/test.dart';

import 'package:observatory/service_io.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

// AUTOGENERATED START
//
// Update these constants by running:
//
// dart pkg/vm_service/test/update_line_numbers.dart runtime/observatory/tests/service/parameters_in_scope_at_entry_test.dart
//
const LINE_0 = 39;
const LINE_A = 40;
const LINE_1 = 43;
const LINE_B = 44;
// AUTOGENERATED END

foo(param) {
  return param;
}

fooClosure() {
  theClosureFunction(param) {
    return param;
  }

  return theClosureFunction;
}

testMain() {
  debugger(); // LINE_0.
  foo("in-scope"); // LINE_A.

  var f = fooClosure();
  debugger(); // LINE_1.
  f("in-scope"); // LINE_B.
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_0),
  stepOver,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  (isolate) => isolate.stepInto(),
  hasStoppedAtBreakpoint,
  (isolate) async {
    var stack = await isolate.getStack();
    Frame top = stack['frames'][0];
    print(top);
    expect(top.function!.name, equals("foo"));
    print(top.variables);
    expect(top.variables.length, equals(1));
    var param = top.variables[0];
    expect(param['name'], equals("param"));
    expect(param['value'].valueAsString, equals("in-scope"));
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_1),
  stepOver,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  (isolate) => isolate.stepInto(),
  hasStoppedAtBreakpoint,
  (isolate) async {
    var stack = await isolate.getStack();
    Frame top = stack['frames'][0];
    print(top);
    expect(top.function!.name, equals("theClosureFunction"));
    print(top.variables);
    expect(top.variables.length, equals(1));
    var param = top.variables[0];
    expect(param['name'], equals("param"));
    expect(param['value'].valueAsString, equals("in-scope"));
  },
  resumeIsolate,
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
