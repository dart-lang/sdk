// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'coverage_async_lib.dart' as testee_lib;

bool allRangesCompiled(coverage) {
  for (int i = 0; i < coverage['ranges'].length; i++) {
    if (!coverage['ranges'][i]['compiled']) {
      return false;
    }
  }
  return true;
}

IsolateTest coverageTest(Map<String, dynamic> expectedRange) {
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
            .firstWhere((l) => l.uri!.contains('coverage_async_lib'))
            .id!) as Library;
    final FuncRef funcRef =
        root.functions!.singleWhere((f) => f.name == 'wrapperFunction');
    final Func func = await service.getObject(isolateId, funcRef.id!) as Func;
    final location = func.location!;

    final report = await service.getSourceReport(
      isolateId,
      [SourceReportKind.kCoverage],
      scriptId: location.script!.id,
      tokenPos: location.tokenPos,
      endTokenPos: location.endTokenPos,
      forceCompile: true,
      reportLines: true,
    );
    expect(report.ranges!.length, 1);
    expect(report.ranges![0].toJson(), expectedRange);
    expect(report.scripts!.length, 1);
    expect(
      report.scripts![0].uri,
      endsWith('coverage_async_lib.dart'),
    );
  };
}

void main([args = const <String>[]]) =>
    IsolateTestHarness('coverage_async_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .addCustomTest(
          coverageTest({
            'scriptIndex': 0,
            'startPos': 552,
            'endPos': 756,
            'compiled': true,
            'coverage': {
              'hits': [],
              'misses': [22, 23, 23, 24, 24, 24, 25, 27, 27, 28]
            }
          }),
        )
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .addCustomTest(
          coverageTest({
            'scriptIndex': 0,
            'startPos': 552,
            'endPos': 756,
            'compiled': true,
            'coverage': {
              'hits': [22, 23, 23, 24, 24, 24, 25, 27, 27, 28],
              'misses': []
            }
          }),
        )
        .run(testeeMain: testee_lib.main);
