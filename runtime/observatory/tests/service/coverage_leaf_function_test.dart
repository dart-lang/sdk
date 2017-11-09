// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'service_test_common.dart';
import 'dart:developer';

String leafFunction() {
  return "some constant";
}

void testFunction() {
  debugger();
  leafFunction();
  debugger();
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
    expect(stack['frames'].length, greaterThanOrEqualTo(1));
    expect(stack['frames'][0].function.name, equals('testFunction'));

    var root = isolate.rootLibrary;
    await root.load();
    var func = root.functions.singleWhere((f) => f.name == 'leafFunction');
    await func.load();

    var expectedRange = {
      'scriptIndex': 0,
      'startPos': ifKernel(456, 26),
      'endPos': ifKernel(499, 38),
      'compiled': true,
      'coverage': {
        'hits': ifKernel([], []),
        'misses': ifKernel([456], [26])
      }
    };

    var params = {
      'reports': ['Coverage'],
      'scriptId': func.location.script.id,
      'tokenPos': func.location.tokenPos,
      'endTokenPos': func.location.endTokenPos,
      'forceCompile': true
    };
    var report = await isolate.invokeRpcNoUpgrade('getSourceReport', params);
    expect(report['type'], equals('SourceReport'));
    expect(report['ranges'].length, 1);
    expect(report['ranges'][0], equals(expectedRange));
    expect(report['scripts'].length, 1);
    expect(report['scripts'][0]['uri'],
        endsWith('coverage_leaf_function_test.dart'));
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    var stack = await isolate.getStack();

    // Make sure we are in the right place.
    expect(stack.type, equals('Stack'));
    expect(stack['frames'].length, greaterThanOrEqualTo(1));
    expect(stack['frames'][0].function.name, equals('testFunction'));

    var root = isolate.rootLibrary;
    await root.load();
    var func = root.functions.singleWhere((f) => f.name == 'leafFunction');
    await func.load();

    var expectedRange = {
      'scriptIndex': 0,
      'startPos': ifKernel(456, 26),
      'endPos': ifKernel(499, 38),
      'compiled': true,
      'coverage': {
        'hits': ifKernel([456], [26]),
        'misses': ifKernel([], [])
      }
    };

    var params = {
      'reports': ['Coverage'],
      'scriptId': func.location.script.id,
      'tokenPos': func.location.tokenPos,
      'endTokenPos': func.location.endTokenPos,
      'forceCompile': true
    };
    var report = await isolate.invokeRpcNoUpgrade('getSourceReport', params);
    expect(report['type'], equals('SourceReport'));
    expect(report['ranges'].length, 1);
    expect(report['ranges'][0], equals(expectedRange));
    expect(report['scripts'].length, 1);
    expect(report['scripts'][0]['uri'],
        endsWith('coverage_leaf_function_test.dart'));
  },
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
