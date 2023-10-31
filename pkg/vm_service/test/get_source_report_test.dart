// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';
import 'common/service_test_common.dart';

const LINE_A = 25;
const LINE_B = 46;

int globalVar = 100;

class MyClass {
  static void myFunction(int value) {
    if (value < 0) {
      print('negative');
    } else {
      print('positive');
    }
    debugger(); // LINE_A
  }

  static void otherFunction(int value) {
    if (value < 0) {
      print('otherFunction <');
    } else {
      print('otherFunction >=');
    }
  }
}

void testFunction() {
  MyClass.otherFunction(-100);
  MyClass.myFunction(10000);
}

class MyConstClass {
  const MyConstClass();
  static const MyConstClass instance = null ?? const MyConstClass();

  void foo() {
    debugger(); // LINE_B
  }
}

void testFunction2() {
  MyConstClass.instance.foo();
}

bool allRangesCompiled(SourceReport coverage) {
  for (final range in coverage.ranges!) {
    if (!range.compiled!) {
      return false;
    }
  }
  return true;
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final stack = await service.getStack(isolateId);
    final func = stack.frames!.first.function!;
    final scriptId = func.location!.script!.id!;

    final expectedRange = SourceReportRange(
      scriptIndex: 0,
      startPos: 478,
      endPos: 632,
      compiled: true,
      coverage: SourceReportCoverage(
        hits: const [478, 528, 579, 608],
        misses: [541],
      ),
    );

    // Full script
    var coverage = await service.getSourceReport(
      isolateId,
      [SourceReportKind.kCoverage],
      scriptId: scriptId,
    );

    var ranges = coverage.ranges!;
    expect(ranges.length, greaterThanOrEqualTo(10));
    // TODO(bkonyi): implement operator== properly.
    expect(ranges[0].toJson(), expectedRange.toJson());

    var scripts = coverage.scripts!;
    expect(coverage.scripts!.length, 1);
    expect(scripts[0].uri!, endsWith('get_source_report_test.dart'));
    expect(allRangesCompiled(coverage), false);

    // Force compilation.
    coverage = await service.getSourceReport(
      isolateId,
      [SourceReportKind.kCoverage],
      scriptId: scriptId,
      forceCompile: true,
    );
    ranges = coverage.ranges!;
    expect(ranges.length, greaterThanOrEqualTo(10));
    expect(allRangesCompiled(coverage), isTrue);

    // One function
    coverage = await service.getSourceReport(
      isolateId,
      [SourceReportKind.kCoverage],
      scriptId: scriptId,
      tokenPos: func.location!.tokenPos!,
      endTokenPos: func.location!.endTokenPos!,
    );
    ranges = coverage.ranges!;
    scripts = coverage.scripts!;
    expect(ranges.length, 1);
    // TODO(bkonyi): implement operator== properly.
    expect(ranges[0].toJson(), expectedRange.toJson());
    expect(scripts.length, 1);
    expect(scripts[0].uri!, endsWith('get_source_report_test.dart'));

    // Full isolate
    coverage = await service.getSourceReport(
      isolateId,
      [SourceReportKind.kCoverage],
    );
    ranges = coverage.ranges!;
    scripts = coverage.scripts!;
    expect(ranges.length, greaterThan(1));
    expect(scripts.length, greaterThan(1));

    // Full isolate
    coverage = await service.getSourceReport(
      isolateId,
      [SourceReportKind.kCoverage],
      forceCompile: true,
    );
    ranges = coverage.ranges!;
    scripts = coverage.scripts!;
    expect(ranges.length, greaterThan(1));
    expect(scripts.length, greaterThan(1));

    // Multiple reports (make sure enum list parameter parsing works).
    coverage = await service.getSourceReport(
      isolateId,
      [
        SourceReportKind.kCoverage,
        SourceReportKind.kPossibleBreakpoints,
        '_CallSites',
      ],
      scriptId: scriptId,
      tokenPos: func.location!.tokenPos!,
      endTokenPos: func.location!.endTokenPos!,
    );
    ranges = coverage.ranges!;
    expect(ranges.length, 1);
    final range = ranges[0];
    expect(coverage.json!['ranges'][0].containsKey('callSites'), true);
    expect(range.coverage, isNotNull);
    expect(range.possibleBreakpoints, isNotNull);

    // missing scriptId with tokenPos.
    bool caughtException = false;
    try {
      await service.getSourceReport(
        isolateId,
        [SourceReportKind.kCoverage],
        tokenPos: func.location!.tokenPos!,
      );
      fail('Unreachable');
    } on RPCError catch (e) {
      caughtException = true;
      expect(e.code, RPCErrorKind.kInvalidParams.code);
      expect(
          e.details,
          "getSourceReport: the 'tokenPos' parameter requires the "
          "\'scriptId\' parameter");
    }
    expect(caughtException, true);

    // missing scriptId with endTokenPos.
    caughtException = false;
    try {
      await service.getSourceReport(
        isolateId,
        [SourceReportKind.kCoverage],
        endTokenPos: func.location!.endTokenPos!,
      );
      fail('Unreachable');
    } on RPCError catch (e) {
      caughtException = true;
      expect(e.code, RPCErrorKind.kInvalidParams.code);
      expect(
          e.details,
          "getSourceReport: the 'endTokenPos' parameter requires the "
          "\'scriptId\' parameter");
    }
    expect(caughtException, true);
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'get_source_report_test.dart',
      testeeConcurrent: testFunction,
    );
