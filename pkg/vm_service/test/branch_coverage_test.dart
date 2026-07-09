// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'branch_coverage_lib.dart' as testee_lib;
import 'common/service_test_common.dart';

IsolateTest coverageTest(
  Map<String, dynamic> expectedRange, {
  required bool reportLines,
}) {
  return (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final stack = await service.getStack(isolateId);

    // Make sure we are in the right place.
    expect(stack.frames!.length, greaterThanOrEqualTo(1));
    expect(stack.frames![0].function!.name, 'testFunction');

    final root = await service.getObject(
        isolateId,
        isolate.libraries!
            .firstWhere((l) => l.uri!.contains('branch_coverage_lib'))
            .id!) as Library;
    final funcRef = root.functions!.singleWhere((f) => f.name == 'ifTest');
    final func = await service.getObject(isolateId, funcRef.id!) as Func;
    final location = func.location!;

    final report = await service.getSourceReport(
      isolateId,
      [SourceReportKind.kBranchCoverage],
      scriptId: location.script!.id,
      tokenPos: location.tokenPos,
      endTokenPos: location.endTokenPos,
      forceCompile: true,
      reportLines: reportLines,
    );
    expect(report.ranges!.length, 1);
    expect(report.ranges![0].toJson(), expectedRange);
    expect(report.scripts!.length, 1);
    expect(report.scripts![0].uri, endsWith('branch_coverage_lib.dart'));
  };
}

void main([args = const <String>[]]) =>
    IsolateTestHarness('branch_coverage_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .addCustomTest(
          coverageTest(
            {
              'scriptIndex': 0,
              'startPos': 277,
              'endPos': 407,
              'compiled': true,
              'branchCoverage': {
                'hits': [],
                'misses': [277, 306, 324, 354, 387],
              },
            },
            reportLines: false,
          ),
        )
        .addCustomTest(
          coverageTest(
            {
              'scriptIndex': 0,
              'startPos': 277,
              'endPos': 407,
              'compiled': true,
              'branchCoverage': {
                'hits': [],
                'misses': [8, 9, 10, 12, 15],
              },
            },
            reportLines: true,
          ),
        )
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .addCustomTest(
          coverageTest(
            {
              'scriptIndex': 0,
              'startPos': 277,
              'endPos': 407,
              'compiled': true,
              'branchCoverage': {
                'hits': [277, 306, 354],
                'misses': [324, 387],
              },
            },
            reportLines: false,
          ),
        )
        .addCustomTest(
          coverageTest(
            {
              'scriptIndex': 0,
              'startPos': 277,
              'endPos': 407,
              'compiled': true,
              'branchCoverage': {
                'hits': [8, 9, 12],
                'misses': [10, 15],
              },
            },
            reportLines: true,
          ),
        )
        .run(testeeMain: testee_lib.main, extraArgs: ['--branch-coverage']);
