// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'coverage_extension_methods_lib.dart' as testee_lib;

Future<({Set<int> hits, Set<int> misses})> verifyLocationAndGetHitsAndMisses(
  VmService service,
  IsolateRef isolateRef,
  TestScriptParser parser,
) async {
  final isolateId = isolateRef.id!;
  final stack = await service.getStack(isolateId);

  // Make sure we are in the right place.
  final frames = stack.frames!;
  expect(frames.length, greaterThanOrEqualTo(1));
  expect(frames[0].function!.name, 'testFunction');

  final location = frames[0].function!.location!;
  final report = await service.getSourceReport(
    isolateId,
    [SourceReportKind.kCoverage],
    scriptId: location.script!.id!,
    tokenPos: parser.offsetForTag('OFFSET_GET_FROM'),
    endTokenPos: parser.offsetForTag('OFFSET_GET_TO'),
    forceCompile: true,
  );

  final scripts = report.scripts!;
  final ranges = report.ranges!;
  final hits = <int>{};
  final misses = <int>{};
  // We have more ranges because there are several methods:
  // The actual method, a tearoff and a closure inside the tearoff.
  for (final range in ranges) {
    hits.addAll(range.coverage!.hits!);
    misses.addAll(range.coverage!.misses!);
    expect(range.startPos, parser.offsetForTag('OFFSET_BAZ_START'));
    expect(range.endPos, parser.offsetForTag('OFFSET_BAZ_END'));
    expect(range.scriptIndex, 0);
  }
  misses.removeAll(hits);
  expect(
    scripts[0].uri,
    endsWith('coverage_extension_methods_lib.dart'),
  );
  return (hits: hits, misses: misses);
}

void main(List<String> args) =>
    IsolateTestHarness('coverage_extension_methods_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .addCustomTestWithParser(
          (VmService service, IsolateRef isolateRef,
              TestScriptParser parser) async {
            final (:hits, :misses) = await verifyLocationAndGetHitsAndMisses(
                service, isolateRef, parser);
            expect(hits, isEmpty);
            expect(misses, {
              parser.offsetForTag('OFFSET_BAZ_START'),
              parser.offsetForTag('OFFSET_PRINT')
            });
          },
        )
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .addCustomTestWithParser(
          (VmService service, IsolateRef isolateRef,
              TestScriptParser parser) async {
            final (:hits, :misses) = await verifyLocationAndGetHitsAndMisses(
                service, isolateRef, parser);
            expect(hits, {
              parser.offsetForTag('OFFSET_BAZ_START'),
              parser.offsetForTag('OFFSET_PRINT')
            });
            expect(misses, isEmpty);
          },
        )
        .run(testeeMain: testee_lib.main);
