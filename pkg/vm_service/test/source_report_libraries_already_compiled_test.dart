// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:developer';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

// ignore_for_file: dead_code

class Class {
  void method() {
    print("hit");
  }

  void missed() {
    print("miss");
  }
}

void unusedFunction() {
  print("miss");
}

void testFunction() {
  if (true) {
    print("hit");
    Class().method();
  } else {
    print("miss");
    unusedFunction();
  }
  debugger();
}

const ignoreHitsBelowThisLine = 39;

const allHits = [15, 16, 28, 30, 31, 36];
final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  librariesAlreadyCompiledTest(false, [], allHits, [33, 34]),
  librariesAlreadyCompiledTest(true, [target], allHits, [33, 34]),
  librariesAlreadyCompiledTest(true, [], allHits, [19, 20, 24, 25, 33, 34]),
  resumeIsolate,
];

final target = Platform.script.toString();

librariesAlreadyCompiledTest(
  bool forceCompile,
  List<String> librariesAlreadyCompiled,
  List<int> expectedHits,
  List<int> expectedMisses,
) =>
    (VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;

      final report = await service.getSourceReport(
        isolateId,
        [SourceReportKind.kCoverage],
        forceCompile: forceCompile,
        reportLines: true,
        librariesAlreadyCompiled: librariesAlreadyCompiled,
      );

      addLines(List<int>? lines, Set<int> out) {
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

main([args = const <String>[]]) async => await runIsolateTests(
      args,
      tests,
      target,
      testeeConcurrent: testFunction,
    );
