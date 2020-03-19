// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

int globalVar = 100;

class MyClass {
  static int staticVar = 1000;

  static void method(int value) {
    debugger();
  }
}

class _MyClass {
  void foo() {
    debugger();
  }
}

void testFunction() {
  int i = 0;
  while (true) {
    if (++i % 100000000 == 0) {
      MyClass.method(10000);
      (new _MyClass()).foo();
    }
  }
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,

// Evaluate against library, class, and instance.
  (Isolate isolate) async {
    ServiceMap stack = await isolate.getStack();

    // Make sure we are in the right place.
    expect(stack.type, equals('Stack'));
    expect(stack['frames'].length, greaterThanOrEqualTo(2));
    expect(stack['frames'][0].function.name, equals('method'));
    expect(stack['frames'][0].function.dartOwner.name, equals('MyClass'));

    var lib = isolate.rootLibrary;
    var cls = stack['frames'][0].function.dartOwner;
    var instance = stack['frames'][0].variables[0]['value'];

    dynamic result = await lib.evaluate('globalVar + 5');
    print(result);
    expect(result.valueAsString, equals('105'));

    await expectError(() => lib.evaluate('globalVar + staticVar + 5'));

    result = await cls.evaluate('globalVar + staticVar + 5');
    print(result);
    expect(result.valueAsString, equals('1105'));

    await expectError(() => cls.evaluate('this + 5'));

    result = await instance.evaluate('this + 5');
    print(result);
    expect(result.valueAsString, equals('10005'));

    await expectError(() => instance.evaluate('this + frog'));
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    ServiceMap stack = await isolate.getStack();

    // Make sure we are in the right place.
    expect(stack.type, equals('Stack'));
    expect(stack['frames'].length, greaterThanOrEqualTo(2));
    expect(stack['frames'][0].function.name, equals('foo'));
    expect(stack['frames'][0].function.dartOwner.name, equals('_MyClass'));

    var cls = stack['frames'][0].function.dartOwner;

    dynamic result = await cls.evaluate("1+1");
    print(result);
    expect(result.valueAsString, equals("2"));
  }
];

expectError(func) async {
  bool gotException = false;
  dynamic result;
  try {
    result = await func();
    expect(result.type, equals('Error')); // dart1 semantics
  } on ServerRpcException catch (e) {
    expect(e.code, equals(ServerRpcException.kExpressionCompilationError));
    gotException = true;
  }
  if (result?.type != 'Error') {
    expect(gotException, true); // dart2 semantics
  }
}

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
