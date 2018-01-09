// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'dart:async';
import 'dart:developer';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

int globalVar = 100;

class MyClass {
  static int staticVar = 1000;

  static void method(int value) {
    debugger();
  }
}

void testFunction() {
  int i = 0;
  while (true) {
    if (++i % 100000000 == 0) {
      MyClass.method(10000);
    }
  }
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,

// Evaluate against library, class, and instance.
  (Isolate isolate) {
    return isolate.getStack().then((ServiceMap stack) {
      // Make sure we are in the right place.
      expect(stack.type, equals('Stack'));
      expect(stack['frames'].length, greaterThanOrEqualTo(2));
      expect(stack['frames'][0].function.name, equals('method'));
      expect(stack['frames'][0].function.dartOwner.name, equals('MyClass'));

      var lib = isolate.rootLibrary;
      var cls = stack['frames'][0].function.dartOwner;
      var instance = stack['frames'][0].variables[0]['value'];

      List evals = [];
      evals.add(lib.evaluate('globalVar + 5').then((result) {
        print(result);
        expect(result.valueAsString, equals('105'));
      }));
      evals.add(lib.evaluate('globalVar + staticVar + 5').then((result) {
        expect(result.type, equals('Error'));
      }));
      evals.add(cls.evaluate('globalVar + staticVar + 5').then((result) {
        print(result);
        expect(result.valueAsString, equals('1105'));
      }));
      evals.add(cls.evaluate('this + 5').then((result) {
        expect(result.type, equals('Error'));
      }));
      evals.add(instance.evaluate('this + 5').then((result) {
        print(result);
        expect(result.valueAsString, equals('10005'));
      }));
      evals.add(instance.evaluate('this + frog').then((result) {
        expect(result.type, equals('Error'));
      }));
      return Future.wait(evals);
    });
  },
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
