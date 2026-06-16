// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'coverage_static_call_after_optimization_lib.dart' as testee_lib;

IsolateTest coverageTest(
  Map<String, dynamic> expectedRange,
) {
  return (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final stack = await service.getStack(isolateId);

    // Make sure we are in the right place.
    final frames = stack.frames!;
    expect(frames.length, greaterThanOrEqualTo(1));
    expect(frames[0].function!.name, 'testFunction');

    final rootLib = await service.getObject(
        isolateId,
        isolate.libraries!
            .firstWhere((l) =>
                l.uri!.contains('coverage_static_call_after_optimization_lib'))
            .id!) as Library;
    final funcRef =
        rootLib.functions!.singleWhere((f) => f.name == 'leafFunction');
    final func = await service.getObject(isolateId, funcRef.id!) as Func;

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
      endsWith('coverage_static_call_after_optimization_lib.dart'),
    );
  };
}

void main([args = const <String>[]]) => IsolateTestHarness(
      'coverage_static_call_after_optimization_lib.dart',
      args,
    )
        .hasStoppedAtBreakpoint()
        .addCustomTest(
          coverageTest({
            'scriptIndex': 0,
            'startPos': 333,
            'endPos': 549,
            'compiled': true,
            'coverage': {
              'hits': [],
              'misses': [333, 447, 453, 479, 485, 495],
            },
          }),
        )
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .addCustomTest(
          coverageTest({
            'scriptIndex': 0,
            'startPos': 333,
            'endPos': 549,
            'compiled': true,
            'coverage': {
              'hits': [333, 447, 453, 479, 485, 495],
              'misses': [],
            },
          }),
        )
        .run(
      testeeMain: testee_lib.main,
      extraArgs: [
        '--deterministic',
        '--optimization-counter-threshold=10',
      ],
    );
