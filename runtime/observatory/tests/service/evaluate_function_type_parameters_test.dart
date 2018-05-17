// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

topLevel<S>() {
  debugger();

  void inner1<T>() {
    debugger();
  }

  inner1<int>();

  void inner2() {
    debugger();
  }

  inner2();
}

class A {
  foo<T>() {
    debugger();
  }
}

void testMain() {
  topLevel<String>();
  (new A()).foo<int>();
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    // Make sure we are in the right place.
    var stack = await isolate.getStack();
    var topFrame = 0;
    expect(stack.type, equals('Stack'));
    expect(await stack['frames'][topFrame].location.getLine(), 14);

    Instance result = await isolate.evalFrame(topFrame, "S.toString()");
    print(result);
    expect(result.valueAsString, equals("String"));
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    // Make sure we are in the right place.
    var stack = await isolate.getStack();
    var topFrame = 0;
    expect(stack.type, equals('Stack'));
    expect(await stack['frames'][topFrame].location.getLine(), 16);

    Instance result = await isolate.evalFrame(topFrame, "T.toString()");
    print(result);
    expect(result.valueAsString, equals("int"));

    result = await isolate.evalFrame(topFrame, "S.toString()");
    print(result);
    expect(result.valueAsString, equals("String"));
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    // Make sure we are in the right place.
    var stack = await isolate.getStack();
    var topFrame = 0;
    expect(stack.type, equals('Stack'));
    expect(await stack['frames'][topFrame].location.getLine(), 22);

    Instance result = await isolate.evalFrame(topFrame, "S.toString()");
    print(result);
    expect(result.valueAsString, equals("String"));
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    // Make sure we are in the right place.
    var stack = await isolate.getStack();
    var topFrame = 0;
    expect(stack.type, equals('Stack'));
    expect(await stack['frames'][topFrame].location.getLine(), 30);

    Instance result = await isolate.evalFrame(topFrame, "T.toString()");
    print(result);
    expect(result.valueAsString, equals("int"));
  },
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
