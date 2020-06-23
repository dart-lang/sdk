// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

topLevel<S>() {
  debugger();

  void inner1<TBool, TString, TDouble, TInt>(TInt x) {
    debugger();
  }

  inner1<bool, String, double, int>(3);

  void inner2() {
    debugger();
  }

  inner2();
}

class A {
  foo<T, S>() {
    debugger();
  }

  bar<T>(T t) {
    debugger();
  }
}

void testMain() {
  topLevel<String>();
  (new A()).foo<int, bool>();
  (new A()).bar<dynamic>(42);
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

    Instance result = await isolate.evalFrame(topFrame, "TBool.toString()");
    print(result);
    expect(result.valueAsString, equals("bool"));

    result = await isolate.evalFrame(topFrame, "TString.toString()");
    print(result);
    expect(result.valueAsString, equals("String"));

    result = await isolate.evalFrame(topFrame, "TDouble.toString()");
    print(result);
    expect(result.valueAsString, equals("double"));

    result = await isolate.evalFrame(topFrame, "TInt.toString()");
    print(result);
    expect(result.valueAsString, equals("int"));

    result = await isolate.evalFrame(topFrame, "S.toString()");
    print(result);
    expect(result.valueAsString, equals("String"));

    result = await isolate.evalFrame(topFrame, "x");
    print(result);
    expect(result.valueAsString, equals("3"));
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

    result = await isolate.evalFrame(topFrame, "S.toString()");
    print(result);
    expect(result.valueAsString, equals("bool"));
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    // Make sure we are in the right place.
    var stack = await isolate.getStack();
    var topFrame = 0;
    expect(stack.type, equals('Stack'));
    expect(await stack['frames'][topFrame].location.getLine(), 34);

    Instance result = await isolate.evalFrame(topFrame, "T.toString()");
    print(result);
    expect(result.valueAsString, equals("dynamic"));
    result = await isolate.evalFrame(topFrame, "t");
    print(result);
    expect(result.valueAsString, equals("42"));
  },
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
