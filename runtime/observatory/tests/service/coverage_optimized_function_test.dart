// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--no_background_compilation --optimization_counter_threshold=10

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'service_test_common.dart';
import 'dart:developer';

String optimizedFunction() {
  return 5.toString() + 3.toString();
}

void testFunction() {
  for (var i = 0; i < 20; i++) {
    optimizedFunction();
  }
  debugger();
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
    var func = root.functions.singleWhere((f) => f.name == 'optimizedFunction');
    await func.load();

    var expectedRange = {
      'scriptIndex': 0,
      'startPos': ifKernel(476, 26),
      'endPos': ifKernel(536, 51),
      'compiled': true,
      'coverage': {
        'hits': ifKernel([476, 509, 520, 524], [26, 37, 41, 45]),
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
        endsWith('coverage_optimized_function_test.dart'));
  },
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
