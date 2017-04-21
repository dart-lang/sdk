// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'service_test_common.dart';
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

bool allRangesCompiled(coverage) {
  for (int i = 0; i < coverage['ranges'].length; i++) {
    if (!coverage['ranges'][i]['compiled']) {
      return false;
    }
  }
  return true;
}

var tests = [
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    var stack = await isolate.getStack();

    // Make sure we are in the right place.
    expect(stack.type, equals('Stack'));
    expect(stack['frames'].length, greaterThanOrEqualTo(2));
    expect(stack['frames'][0].function.name, equals('myFunction'));
    expect(stack['frames'][0].function.dartOwner.name, equals('MyClass'));

    var func = stack['frames'][0].function;
    expect(func.name, equals('myFunction'));
    await func.load();

    var expectedRange = {
      'scriptIndex': 0,
      'startPos': ifKernel(501, 39),
      'endPos': ifKernel(633, 88),
      'compiled': true,
      'coverage': {
        'hits': ifKernel([539, 590, 619], [54, 72, 82]),
        'misses': ifKernel([552], [60])
      }
    };

    // Full script
    var params = {
      'reports': ['Coverage'],
      'scriptId': func.location.script.id
    };
    var coverage = await isolate.invokeRpcNoUpgrade('getSourceReport', params);
    expect(coverage['type'], equals('SourceReport'));
    expect(coverage['ranges'].length, 6);
    expect(coverage['ranges'][0], equals(expectedRange));
    expect(coverage['scripts'].length, 1);
    expect(
        coverage['scripts'][0]['uri'], endsWith('get_source_report_test.dart'));
    expect(allRangesCompiled(coverage), isFalse);

    // Force compilation.
    params = {
      'reports': ['Coverage'],
      'scriptId': func.location.script.id,
      'forceCompile': true
    };
    coverage = await isolate.invokeRpcNoUpgrade('getSourceReport', params);
    expect(coverage['type'], equals('SourceReport'));
    expect(coverage['ranges'].length, 6);
    expect(allRangesCompiled(coverage), isTrue);

    // One function
    params = {
      'reports': ['Coverage'],
      'scriptId': func.location.script.id,
      'tokenPos': func.location.tokenPos,
      'endTokenPos': func.location.endTokenPos
    };
    coverage = await isolate.invokeRpcNoUpgrade('getSourceReport', params);
    expect(coverage['type'], equals('SourceReport'));
    expect(coverage['ranges'].length, 1);
    expect(coverage['ranges'][0], equals(expectedRange));
    expect(coverage['scripts'].length, 1);
    expect(
        coverage['scripts'][0]['uri'], endsWith('get_source_report_test.dart'));

    // Full isolate
    params = {
      'reports': ['Coverage']
    };
    coverage = await isolate.invokeRpcNoUpgrade('getSourceReport', params);
    expect(coverage['type'], equals('SourceReport'));
    expect(coverage['ranges'].length, greaterThan(1));
    expect(coverage['scripts'].length, greaterThan(1));

    // Multiple reports (make sure enum list parameter parsing works).
    params = {
      'reports': ['_CallSites', 'Coverage', 'PossibleBreakpoints'],
      'scriptId': func.location.script.id,
      'tokenPos': func.location.tokenPos,
      'endTokenPos': func.location.endTokenPos
    };
    coverage = await isolate.invokeRpcNoUpgrade('getSourceReport', params);
    expect(coverage['type'], equals('SourceReport'));
    expect(coverage['ranges'].length, 1);
    var range = coverage['ranges'][0];
    expect(range.containsKey('callSites'), isTrue);
    expect(range.containsKey('coverage'), isTrue);
    expect(range.containsKey('possibleBreakpoints'), isTrue);

    // missing scriptId with tokenPos.
    bool caughtException = false;
    try {
      params = {
        'reports': ['Coverage'],
        'tokenPos': func.location.tokenPos
      };
      coverage = await isolate.invokeRpcNoUpgrade('getSourceReport', params);
    } on ServerRpcException catch (e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kInvalidParams));
      expect(
          e.message,
          "getSourceReport: the 'tokenPos' parameter requires the "
          "\'scriptId\' parameter");
    }
    expect(caughtException, isTrue);

    // missing scriptId with endTokenPos.
    caughtException = false;
    try {
      params = {
        'reports': ['Coverage'],
        'endTokenPos': func.location.endTokenPos
      };
      coverage = await isolate.invokeRpcNoUpgrade('getSourceReport', params);
    } on ServerRpcException catch (e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kInvalidParams));
      expect(
          e.message,
          "getSourceReport: the 'endTokenPos' parameter requires the "
          "\'scriptId\' parameter");
    }
    expect(caughtException, isTrue);
  },
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
