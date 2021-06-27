// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

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

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final stack = await service.getStack(isolateId);

    // Make sure we are in the right place.
    expect(stack.frames!.length, greaterThanOrEqualTo(1));
    expect(stack.frames![0].function!.name, 'testFunction');

    final Library root =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;
    FuncRef funcRef =
        root.functions!.singleWhere((f) => f.name == 'leafFunction');
    Func func = await service.getObject(isolateId, funcRef.id!) as Func;

    final expectedRange = {
      'scriptIndex': 0,
      'startPos': 397,
      'endPos': 447,
      'compiled': true,
      'coverage': {
        'hits': [],
        'misses': [397]
      }
    };
    final location = func.location!;

    final report = await service.getSourceReport(
        isolateId, [SourceReportKind.kCoverage],
        scriptId: location.script!.id,
        tokenPos: location.tokenPos,
        endTokenPos: location.endTokenPos,
        forceCompile: true);
    expect(report.ranges!.length, 1);
    expect(report.ranges![0].toJson(), expectedRange);
    expect(report.scripts!.length, 1);
    expect(
        report.scripts![0].uri, endsWith('coverage_leaf_function_test.dart'));
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final stack = await service.getStack(isolateId);

    // Make sure we are in the right place.
    expect(stack.frames!.length, greaterThanOrEqualTo(1));
    expect(stack.frames![0].function!.name, 'testFunction');

    final Library root =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;
    FuncRef funcRef =
        root.functions!.singleWhere((f) => f.name == 'leafFunction');
    Func func = await service.getObject(isolateId, funcRef.id!) as Func;

    var expectedRange = {
      'scriptIndex': 0,
      'startPos': 397,
      'endPos': 447,
      'compiled': true,
      'coverage': {
        'hits': [397],
        'misses': []
      }
    };

    final location = func.location!;
    final report = await service.getSourceReport(
        isolateId, [SourceReportKind.kCoverage],
        scriptId: location.script!.id,
        tokenPos: location.tokenPos,
        endTokenPos: location.endTokenPos,
        forceCompile: true);
    expect(report.ranges!.length, 1);
    expect(report.ranges![0].toJson(), expectedRange);
    expect(report.scripts!.length, 1);
    expect(
        report.scripts![0].uri, endsWith('coverage_leaf_function_test.dart'));
  },
];

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'coverage_leaf_function_test.dart',
      testeeConcurrent: testFunction,
    );
