// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'source_report_libraries_already_compiled_lib.dart' as testee_lib;

const ignoreHitsBelowThisLine = 35;

const allHits = [12, 13, 25, 27, 28, 33];

Future<void> Function(VmService service, IsolateRef isolateRef)
    librariesAlreadyCompiledTest(
  bool forceCompile,
  bool includeTarget,
  List<int> expectedHits,
  List<int> expectedMisses,
) =>
        (VmService service, IsolateRef isolateRef) async {
          final isolateId = isolateRef.id!;

          final scripts = await service.getScripts(isolateId);
          final target = scripts.scripts!
              .firstWhere(
                (s) => s.uri!.endsWith(
                  'source_report_libraries_already_compiled_lib.dart',
                ),
              )
              .uri!;

          final report = await service.getSourceReport(
            isolateId,
            [SourceReportKind.kCoverage],
            forceCompile: forceCompile,
            reportLines: true,
            librariesAlreadyCompiled: includeTarget ? [target] : [],
          );

          void addLines(List<int>? lines, Set<int> out) {
            for (final line in lines ?? []) {
              if (line < ignoreHitsBelowThisLine) {
                out.add(line);
              }
            }
          }

          final hits = <int>{};
          final misses = <int>{};
          for (final range in report.ranges!) {
            if (report.scripts?[range.scriptIndex!].uri == target) {
              addLines(range.coverage?.hits, hits);
              addLines(range.coverage?.misses, misses);
            }
          }

          expect(hits, unorderedEquals(expectedHits));
          expect(misses, unorderedEquals(expectedMisses));
        };

void main([args = const <String>[]]) => IsolateTestHarness(
      'source_report_libraries_already_compiled_lib.dart',
      args,
    )
        .hasStoppedAtBreakpoint()
        .addCustomTest(
          librariesAlreadyCompiledTest(false, false, allHits, [30, 31]),
        )
        .addCustomTest(
          librariesAlreadyCompiledTest(true, true, allHits, [30, 31]),
        )
        .addCustomTest(
          librariesAlreadyCompiledTest(
            true,
            false,
            allHits,
            [16, 17, 21, 22, 30, 31],
          ),
        )
        .resumeIsolate()
        .run(testeeMain: testee_lib.main);
