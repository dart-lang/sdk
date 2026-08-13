// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'source_report_package_filters_lib.dart' as testee_lib;

IsolateTest filterTestImpl(List<String> filters, Function(Set<String>) check) {
  return (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;

    final report = await service.getSourceReport(
      isolateId,
      [SourceReportKind.kCoverage],
      forceCompile: true,
      libraryFilters: filters,
    );
    check(Set.of(report.scripts!.map((s) => s.uri!)));
  };
}

IsolateTest filterTestExactlyMatches(
  List<String> filters,
  List<String> expectedScripts,
) =>
    filterTestImpl(filters, (Set<String> scripts) {
      expect(scripts, unorderedEquals(expectedScripts));
    });

IsolateTest filterTestContains(
  List<String> filters,
  List<String> expectedScripts,
) =>
    filterTestImpl(filters, (Set<String> scripts) {
      expect(scripts, containsAll(expectedScripts));
    });

void main([args = const <String>[]]) => IsolateTestHarness(
      'source_report_package_filters_lib.dart',
      args,
    )
        .hasStoppedAtBreakpoint()
        .addCustomTest(
          filterTestExactlyMatches(
            ['package:test_pack'],
            [
              'package:test_package/has_part.dart',
              'package:test_package/the_part.dart',
              'package:test_package/the_part_2.dart',
            ],
          ),
        )
        .addCustomTest(
          filterTestExactlyMatches(
            ['package:test_package/'],
            [
              'package:test_package/has_part.dart',
              'package:test_package/the_part.dart',
              'package:test_package/the_part_2.dart',
            ],
          ),
        )
        .addCustomTest(
          filterTestExactlyMatches(
            ['zzzzzzzzzzz'],
            [],
          ),
        )
        .addCustomTest(
          filterTestContains(
            ['dart:math'],
            ['dart:math/point.dart'],
          ),
        )
        .addCustomTest(
          filterTestContains(
            ['package:vm'],
            ['package:vm_service/src/vm_service.dart'],
          ),
        )
        .resumeIsolate()
        .run(testeeMain: testee_lib.main);
