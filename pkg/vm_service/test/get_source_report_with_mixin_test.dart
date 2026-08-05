// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'get_source_report_with_mixin_lib.dart' as testee_lib;

const lib1Filename = 'get_source_report_with_mixin_lib1';

Set<int> getHitsForLib1(SourceReport coverage, String uriContains) {
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
        for (final hit in range.coverage!.hits!) {
          hits.add(hit);
        }
      }
    }
  }
  return hits;
}

void main([args = const <String>[]]) =>
    IsolateTestHarness('get_source_report_with_mixin_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final scripts = await service.getScripts(isolateId);
      ScriptRef? foundScript;
      for (ScriptRef script in scripts.scripts!) {
        if (script.uri!.contains(lib1Filename)) {
          foundScript = script;
          break;
        }
      }

      if (foundScript == null) {
        fail('Failed to find script');
      }

      Set<int> hits;
      {
        // Get report for everything; then collect for lib1.
        final coverage = await service.getSourceReport(
          isolateId,
          [SourceReportKind.kCoverage],
        );
        hits = getHitsForLib1(coverage, lib1Filename);
        expect(hits.length, greaterThanOrEqualTo(2));
        print(hits);
      }
      {
        // Now get report for the lib1 only.
        final coverage = await service.getSourceReport(
          isolateId,
          [SourceReportKind.kCoverage],
          scriptId: foundScript.id!,
        );
        final localHits = getHitsForLib1(coverage, lib1Filename);
        expect(localHits.length, hits.length);
        expect(hits.toList()..sort(), localHits.toList()..sort());
        print(localHits);
      }
    }).run(testeeMain: testee_lib.main);
