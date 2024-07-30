// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

class Foo {
  List<String> foos = ['foo1', 'foo2'];
}

@pragma('vm:never-inline')
String leafFunction(List<Foo> foos, bool intoIf) {
  if (intoIf) {
    for (Foo foo in foos) {
      for (var f in foo.foos) {
        print(f);
      }
    }
  }
  return 'some constant';
}

const optimizationCounterThreshold = 10;

void testFunction() {
  debugger();
  final List<Foo> foos = [Foo()];
  // Note that if we do `optimizationCounterThreshold - 2` here
  // optimization doesn't kick in.
  for (int i = 0; i < optimizationCounterThreshold; i++) {
    leafFunction(foos, false);
  }
  // Assuming `leafFunction` is optimized now, does coverage still work?
  leafFunction(foos, true);
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
      'startPos': 454,
      'endPos': 670,
      'compiled': true,
      'coverage': {
        'hits': [],
        'misses': [454, 568, 574, 600, 606, 616],
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
      endsWith('coverage_static_call_after_optimization_test.dart'),
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
      'startPos': 454,
      'endPos': 670,
      'compiled': true,
      'coverage': {
        'hits': [454, 568, 574, 600, 606, 616],
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
      endsWith('coverage_static_call_after_optimization_test.dart'),
    );
  },
];

void main(List<String> args) => runIsolateTests(
      args,
      tests,
      'coverage_static_call_after_optimization_test.dart',
      testeeConcurrent: testFunction,
      extraArgs: [
        '--deterministic',
        '--optimization-counter-threshold=$optimizationCounterThreshold',
      ],
    );
