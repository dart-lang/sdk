// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override  --verbose_debug

import 'package:observatory/service_io.dart';
import 'test_helper.dart';
import 'dart:developer';
import 'package:unittest/unittest.dart';

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
  debugger();
  foo("in-scope");  // Line 24

  var f = fooClosure();
  debugger();
  f("in-scope");  // Line 28
}

var tests = [
  hasStoppedAtBreakpoint,
  stoppedAtLine(24),
  (isolate) => isolate.stepInto(),
  hasStoppedAtBreakpoint,
  (isolate) async {
    var stack = await isolate.getStack();
    Frame top = stack['frames'][0];
    print(top);
    expect(top.function.name, equals("foo"));
    print(top.variables);
    expect(top.variables.length, equals(1));
    var param = top.variables[0];
    expect(param['name'], equals("param"));
    expect(param['value'].valueAsString, equals("in-scope"));
  },
  resumeIsolate,

  hasStoppedAtBreakpoint,
  stoppedAtLine(28),
  (isolate) => isolate.stepInto(),
  hasStoppedAtBreakpoint,
  (isolate) async {
    var stack = await isolate.getStack();
    Frame top = stack['frames'][0];
    print(top);
    expect(top.function.name, equals("theClosureFunction"));
    print(top.variables);
    expect(top.variables.length, equals(1));
    var param = top.variables[0];
    expect(param['name'], equals("param"));
    expect(param['value'].valueAsString, equals("in-scope"));
  },
  resumeIsolate,
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
