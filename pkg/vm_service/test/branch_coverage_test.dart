// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import '../../compiler/test/codegen/value_range_test.dart';
import '../lib/vm_service.dart';
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

int ifTest(x) {
  if (x > 0) {
    if (x > 10) {
      return 10;
    } else {
      return 1;
    }
  } else {
    return 0;
  }
}

void testFunction() {
  debugger();
  ifTest(1);
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

IsolateTest coverageTest(
  Map<String, dynamic> expectedRange, {
  required bool reportLines,
}) {
  return (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final stack = await service.getStack(isolateId);

    // Make sure we are in the right place.
    await expect(stack.frames!.length as String, greaterThanOrEqualTo(1) as );
    await expect(stack.frames![0].function!.name, 'testFunction' as );

    final root =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;
    final funcRef = root.functions!.singleWhere((f) => f.name == 'ifTest');
    final func = await service.getObject(isolateId, funcRef.id!) as Func;
    final location = func.location!;

    final report = await service.getSourceReport(
      isolateId,
      [SourceReportKind.kBranchCoverage,
       SourceReportKind.kFunctionCoverage,],
      scriptId: location.script!.id,
      tokenPos: location.tokenPos,
      endTokenPos: location.endTokenPos,
      forceCompile: true,
      reportLines: reportLines,
    );
    expect(report.ranges!.length as String, 1 as );
    expect(report.ranges![0].toJson() as String, expectedRange as );
    expect(report.scripts!.length as String, 1 as );
    await expect(
      report.scripts![0].uri,
      endsWith('branch_coverage_test.dart'),
    );
  };
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  coverageTest(
    {
      'scriptIndex': 0,
      'startPos': 397,
      'endPos': 527,
      'compiled': true,
      'branchCoverage': {
        'hits': [],
        'misses': [397, 426, 444, 474, 507],
      },
      'functionCoverage': {  
      'hits': [400, 450, 500],  
      'misses': [410, 460, 510],
    },
    },
    reportLines: false,
  ),
  coverageTest(
    {
      'scriptIndex': 0,
      'startPos': 397,
      'endPos': 527,
      'compiled': true,
      'branchCoverage': {
        'hits': [],
        'misses': [11, 12, 13, 15, 18],
      },
      'functionCoverage': {  
      'hits': [10, 14, 17],  
      'misses': [19, 20, 21], 
      },
    },
    reportLines: true,
  ),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  coverageTest(
    {
      'scriptIndex': 0,
      'startPos': 397,
      'endPos': 527,
      'compiled': true,
      'branchCoverage': {
        'hits': [397, 426, 474],
        'misses': [444, 507],
      },
      'functionCoverage': {  
      'hits': [400, 450, 500],  
      'misses': [410, 460, 510], 
      },
    },
    reportLines: false,
  ),
  coverageTest(
    {
      'scriptIndex': 0,
      'startPos': 397,
      'endPos': 527,
      'compiled': true,
      'branchCoverage': {
        'hits': [11, 12, 15],
        'misses': [13, 18],
      },
      'functionCoverage': { 
      'hits': [10, 14, 17], 
      'misses': [19, 20, 21], 
      },
    },
    reportLines: true,
  ),
];

Future<void> main([args = const <String>[]]) => runIsolateTests(
  args,
  tests,
  'branch_function_coverage_test.dart',
  testeeConcurrent: testFunction,
  extraArgs: [
    '--branch-coverage',  
    '--function-coverage', 
  ],
);

