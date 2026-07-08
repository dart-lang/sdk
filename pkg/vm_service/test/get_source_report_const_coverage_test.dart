// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'get_source_report_const_coverage_lib.dart' as testee_lib;

Set<int> getHitsFor(SourceReport coverage, String uriContains) {
  final scripts = coverage.scripts!;
  final scriptIdsWanted = <int>{};
  for (int i = 0; i < scripts.length; i++) {
    final script = scripts[i];
    final scriptUri = script.uri!;
    if (scriptUri.contains(uriContains)) {
      scriptIdsWanted.add(i);
    }
  }
  final ranges = coverage.ranges!;
  final hits = <int>{};
  for (final range in ranges) {
    if (scriptIdsWanted.contains(range.scriptIndex!)) {
      if (range.coverage != null) {
        for (int hit in range.coverage!.hits!) {
          hits.add(hit);
        }
      }
    }
  }
  return hits;
}

void main([args = const <String>[]]) =>
    IsolateTestHarness('get_source_report_const_coverage_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .addCustomTestWithParser((
      VmService service,
      IsolateRef isolateRef,
      TestScriptParser parser,
    ) async {
      final lineA = parser.lineForTag('LINE_A');
      final lineB = parser.lineForTag('LINE_B');
      final lineC = parser.lineForTag('LINE_C');
      final lineD = parser.lineForTag('LINE_D');

      final expectedLinesHit = <int>{lineA, lineB, lineD};
      final expectedLinesNotHit = <int>{lineC};

      final isolateId = isolateRef.id!;
      final isolate = await service.getIsolate(isolateId);
      final rootLibId = isolate.libraries!
          .firstWhere(
              (l) => l.uri!.contains('get_source_report_const_coverage_lib'))
          .id!;
      final rootLib = await service.getObject(isolateId, rootLibId) as Library;
      Script? foundScript;
      for (ScriptRef script in rootLib.scripts!) {
        if (script.uri!.contains('get_source_report_const_coverage_lib.dart')) {
          foundScript =
              await service.getObject(isolateId, script.id!) as Script;
          break;
        }
      }

      if (foundScript == null) {
        fail('Failed to find script');
      }

      Set<int> hits;
      {
        // Get report for everything; then collect for this library.
        final coverage = await service.getSourceReport(
          isolateId,
          [SourceReportKind.kCoverage],
          forceCompile: true,
        );
        hits = getHitsFor(
          coverage,
          'get_source_report_const_coverage_lib.dart',
        );
        final lines = <int>{};
        for (int hit in hits) {
          // We expect every hit to be translatable to line
          // (i.e. tokenToLine to return non-null).
          final line = foundScript.getLineNumberFromTokenPos(hit);
          lines.add(line!);
        }
        print('Token position hits: $hits --- line hits: $lines');
        expect(lines.intersection(expectedLinesHit), expectedLinesHit);
        expect(lines.intersection(expectedLinesNotHit), isEmpty);
      }
      {
        // Now get report for the this file only.
        final coverage = await service.getSourceReport(
          isolateId,
          [SourceReportKind.kCoverage],
          scriptId: foundScript.id!,
          forceCompile: true,
        );
        final localHits = getHitsFor(
          coverage,
          'get_source_report_const_coverage_lib.dart',
        );
        expect(localHits.length, hits.length);
        expect(hits.toList()..sort(), localHits.toList()..sort());
        print(localHits);
      }
    }).run(testeeMain: testee_lib.main);
