// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

@pragma('vm:never-inline')
String leafFunction(void Function() f, bool intoIf) {
  if (intoIf) {
    f();
  }
  return 'some constant';
}

const optimizationCounterThreshold = 10;

void testFunction() {
  debugger();
  // If we do `optimizationCounterThreshold - 2` here optimization doesn't kick
  // in and the test (which otherwise currently fails) passes.
  for (int i = 0; i < optimizationCounterThreshold; i++) {
    leafFunction(() {}, false);
  }
  // Assuming `leafFunction` is optimized now, does coverage still work?
  // Note that I via `--print_flow_graph --print_flow_graph_optimized \
  // --print-flow-graph-filter=leafFunction` can see that it is, but that
  // `func.code?.isOptimized` is false for whatever reason.
  leafFunction(() {}, true);
  debugger();
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final stack = await service.getStack(isolateId);

    // Make sure we are in the right place.
    final frames = stack.frames!;
    expect(frames.length, greaterThanOrEqualTo(1));
    expect(frames[0].function!.name, 'testFunction');

    final rootLib =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;
    final funcRef =
        rootLib.functions!.singleWhere((f) => f.name == 'leafFunction');
    final func = await service.getObject(isolateId, funcRef.id!) as Func;

    final expectedRange = {
      'scriptIndex': 0,
      'startPos': 399,
      'endPos': 535,
      'compiled': true,
      'coverage': {
        'hits': [],
        'misses': [399, 501],
      },
    };

    final location = func.location!;
    final report = await service.getSourceReport(
      isolateId,
      [SourceReportKind.kCoverage],
      scriptId: location.script!.id!,
      tokenPos: location.tokenPos,
      endTokenPos: location.endTokenPos,
      forceCompile: true,
    );

    final ranges = report.ranges!;
    final scripts = report.scripts!;
    expect(ranges.length, 1);
    expect(ranges[0].toJson(), expectedRange);
    expect(scripts.length, 1);
    expect(
      scripts[0].uri,
      endsWith('coverage_closure_call_after_optimization_test.dart'),
    );
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final stack = await service.getStack(isolateId);

    // Make sure we are in the right place.
    final frames = stack.frames!;
    expect(frames.length, greaterThanOrEqualTo(1));
    expect(frames[0].function!.name, 'testFunction');

    final rootLib =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;
    final funcRef =
        rootLib.functions!.singleWhere((f) => f.name == 'leafFunction');
    final func = await service.getObject(isolateId, funcRef.id!) as Func;

    final expectedRange = {
      'scriptIndex': 0,
      'startPos': 399,
      'endPos': 535,
      'compiled': true,
      'coverage': {
        'hits': [399, 501],
        'misses': [],
      },
    };

    final location = func.location!;
    final report = await service.getSourceReport(
      isolateId,
      [SourceReportKind.kCoverage],
      scriptId: location.script!.id!,
      tokenPos: location.tokenPos,
      endTokenPos: location.endTokenPos,
      forceCompile: true,
    );

    final ranges = report.ranges!;
    final scripts = report.scripts!;
    expect(ranges.length, 1);
    expect(ranges[0].toJson(), expectedRange);
    expect(scripts.length, 1);
    expect(
      scripts[0].uri,
      endsWith('coverage_closure_call_after_optimization_test.dart'),
    );
  },
];

void main(List<String> args) => runIsolateTests(
      args,
      tests,
      'coverage_closure_call_after_optimization_test.dart',
      testeeConcurrent: testFunction,
      extraArgs: [
        '--deterministic',
        '--optimization-counter-threshold=$optimizationCounterThreshold',
      ],
    );
