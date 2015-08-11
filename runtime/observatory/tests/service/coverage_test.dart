// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'dart:developer';

int globalVar = 100;

class MyClass {
  static void myFunction(int value) {
    if (value < 0) {
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
  MyClass.otherFunction(-100);
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
         equals([15, 1, 16, 0, 18, 1, 20, 1]));

  // Class
  coverage = await isolate.invokeRpcNoUpgrade('_getCoverage',
                                              { 'targetId': cls.id });
  expect(coverage['type'], equals('CodeCoverage'));
  expect(coverage['coverage'].length, equals(1));
  expect(coverage['coverage'][0]['hits'],
         equals([15, 1, 16, 0, 18, 1, 20, 1,
                 24, 1, 25, 1, 27, 0]));

  // Library
  coverage = await isolate.invokeRpcNoUpgrade('_getCoverage',
                                              { 'targetId': lib.id });
  expect(coverage['type'], equals('CodeCoverage'));
  expect(coverage['coverage'].length, equals(3));
  expect(coverage['coverage'][0]['hits'],
         equals([15, 1, 16, 0, 18, 1, 20, 1,
                 24, 1, 25, 1, 27, 0]));
  expect(coverage['coverage'][1]['hits'].take(12),
         equals([33, 1, 34, 1, 32, 1, 105, 2, 105, 1]));

  // Script
  await cls.load();
  coverage = await isolate.invokeRpcNoUpgrade('_getCoverage',
                                       { 'targetId': cls.location.script.id });
  expect(coverage['type'], equals('CodeCoverage'));
  expect(coverage['coverage'].length, equals(3));
  expect(coverage['coverage'][0]['hits'],
         equals([15, 1, 16, 0, 18, 1, 20, 1,
                 24, 1, 25, 1, 27, 0]));
  expect(coverage['coverage'][1]['hits'].take(12),
         equals([33, 1, 34, 1, 32, 1, 105, 2, 105, 1]));

  // Isolate
  coverage = await isolate.invokeRpcNoUpgrade('_getCoverage', {});
  expect(coverage['type'], equals('CodeCoverage'));
  expect(coverage['coverage'].length, greaterThan(100));
},

];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
