// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';
import 'common/service_test_common.dart';

String leafFunction(void Function() f) {
  f();
  return "some constant";
}

void testFunction() {
  debugger();
  leafFunction(() {});
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

final tests = <IsolateTest>[
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
      'endPos': 473,
      'compiled': true,
      'coverage': {
        'hits': [],
        'misses': [399, 443]
      }
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
    expect(scripts[0].uri, endsWith('coverage_closure_call_test.dart'));
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
      'endPos': 473,
      'compiled': true,
      'coverage': {
        'hits': [399, 443],
        'misses': []
      }
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
    expect(scripts[0].uri, endsWith('coverage_closure_call_test.dart'));
  },
];

void main(List<String> args) => runIsolateTests(
      args,
      tests,
      'coverage_closure_call_test.dart',
      testeeConcurrent: testFunction,
    );
