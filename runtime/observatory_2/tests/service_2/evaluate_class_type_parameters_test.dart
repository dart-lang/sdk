// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

class A<T> {
  void foo() {
    debugger();
  }
}

class B<S> extends A<int> {
  void bar() {
    debugger();
  }
}

testFunction() {
  var v = new B<String>();
  v.bar();
  v.foo();
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    // Make sure we are in the right place.
    var stack = await isolate.getStack();
    var topFrame = 0;
    expect(stack.type, equals('Stack'));
    expect(await stack['frames'][topFrame].location.getLine(), 20);

    Instance result = await isolate.evalFrame(topFrame, '"\$S"');
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
    expect(await stack['frames'][topFrame].location.getLine(), 14);

    Instance result = await isolate.evalFrame(topFrame, '"\$T"');
    print(result);
    expect(result.valueAsString, equals("int"));
  },
  resumeIsolate,
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
