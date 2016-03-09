// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'service_test_common.dart';
import 'dart:developer';

const int LINE_A = 20;
const int LINE_B = 38;
const int LINE_C = 136;

int globalVar = 100;

class MyClass {
  static void myFunction(int value) {
    if (value < 0) {  // Line A.
      print("negative");
    } else {
      print("positive");
    }
    debugger();
  }

  static void otherFunction(int value) {
    if (value < 0) {
               print("otherFunction <");
    } else {
         print("otherFunction >=");
    }
  }
}

void testFunction() {
  MyClass.otherFunction(-100);  // Line B.
  MyClass.myFunction(10000);
}

var tests = [

hasStoppedAtBreakpoint,

// Get coverage for function, class, library, script, and isolate.
(Isolate isolate) async {
  var stack = await isolate.getStack();

  // Make sure we are in the right place.
  expect(stack.type, equals('Stack'));
  expect(stack['frames'].length, greaterThanOrEqualTo(2));
  expect(stack['frames'][0].function.name, equals('myFunction'));
  expect(stack['frames'][0].function.dartOwner.name, equals('MyClass'));

  var lib = isolate.rootLibrary;
  var func = stack['frames'][0].function;
  expect(func.name, equals('myFunction'));
  var cls = func.dartOwner;
  expect(cls.name, equals('MyClass'));

  // Function
  var coverage = await isolate.invokeRpcNoUpgrade('_getCoverage',
                                                  { 'targetId': func.id });
  expect(coverage['type'], equals('CodeCoverage'));
  expect(coverage['coverage'].length, equals(1));
  expect(coverage['coverage'][0]['hits'],
         equals([LINE_A, 1,
                 LINE_A + 1, 0,
                 LINE_A + 3, 1,
                 LINE_A + 5, 1]));

  // Class
  coverage = await isolate.invokeRpcNoUpgrade('_getCoverage',
                                              { 'targetId': cls.id });
  expect(coverage['type'], equals('CodeCoverage'));
  expect(coverage['coverage'].length, equals(1));
  expect(coverage['coverage'][0]['hits'],
         equals([LINE_A, 1,
                 LINE_A + 1, 0,
                 LINE_A + 3, 1,
                 LINE_A + 5, 1,
                 LINE_A + 9, 1,
                 LINE_A + 10, 1,
                 LINE_A + 12, 0,
                 LINE_A - 2, 0]));

  // Library
  coverage = await isolate.invokeRpcNoUpgrade('_getCoverage',
                                              { 'targetId': lib.id });
  expect(coverage['type'], equals('CodeCoverage'));
  expect(coverage['coverage'].length, equals(4));
  expect(coverage['coverage'][0]['hits'],
         equals([LINE_A, 1,
                 LINE_A + 1, 0,
                 LINE_A + 3, 1,
                 LINE_A + 5, 1,
                 LINE_A + 9, 1,
                 LINE_A + 10, 1,
                 LINE_A + 12, 0,
                 LINE_A - 2, 0]));
  expect(coverage['coverage'][1]['hits'],
         equals([LINE_B, 1,
                 LINE_B + 1, 1,
                 LINE_C, 2]));

  // Script
  await cls.load();
  coverage = await isolate.invokeRpcNoUpgrade('_getCoverage',
                                       { 'targetId': cls.location.script.id });
  expect(coverage['type'], equals('CodeCoverage'));
  expect(coverage['coverage'].length, equals(4));
  expect(coverage['coverage'][0]['hits'],
         equals([LINE_A, 1,
                 LINE_A + 1, 0,
                 LINE_A + 3, 1,
                 LINE_A + 5, 1,
                 LINE_A + 9, 1,
                 LINE_A + 10, 1,
                 LINE_A + 12, 0,
                 LINE_A - 2, 0]));
  expect(coverage['coverage'][1]['hits'],
         equals([LINE_B, 1,
                 LINE_B + 1, 1,
                 LINE_C, 2]));

  // Isolate
  coverage = await isolate.invokeRpcNoUpgrade('_getCoverage', {});
  print('Done processing _getCoverage for full isolate');
  expect(coverage['type'], equals('CodeCoverage'));
  expect(coverage['coverage'].length, greaterThan(100));
},

];

main(args) => runIsolateTests(args, tests,    // Line C.
                              testeeConcurrent: testFunction,
                              trace_service: true);
