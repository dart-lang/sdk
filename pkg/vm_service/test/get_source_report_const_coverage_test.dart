// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';
import 'common/service_test_common.dart';

import 'get_source_report_const_coverage_lib.dart' as lib;

const filename = 'get_source_report_const_coverage_test';
const expectedLinesHit = <int>{24, 26, 30};
const expectedLinesNotHit = <int>{28};

const LINE_A = 45;

class Foo {
  final int x;
  // Expect this constructor to be coverage by coverage.
  const Foo([int? x]) : this.x = x ?? 42;
  // Expect this constructor to be coverage by coverage too.
  const Foo.named1([int? x]) : this.x = x ?? 42;
  // Expect this constructor to *NOT* be coverage by coverage.
  const Foo.named2([int? x]) : this.x = x ?? 42;
  // Expect this constructor to be coverage by coverage too (from lib).
  const Foo.named3([int? x]) : this.x = x ?? 42;
}

void testFunction() {
  const foo = Foo();
  const foo2 = Foo();
  const fooIdentical = identical(foo, foo2);
  print(fooIdentical);

  const namedFoo = Foo.named1();
  const namedFoo2 = Foo.named1();
  // ignore: unused_local_variable
  const namedIdentical = identical(namedFoo, namedFoo2);
  print(fooIdentical);

  debugger(); // LINE_A

  // That this is called after (or at all) is not relevent for the code
  // coverage of constants.
  lib.testFunction();

  print('Done');
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLibId = isolate.rootLib!.id!;
    final rootLib = await service.getObject(isolateId, rootLibId) as Library;
    Script? foundScript;
    for (ScriptRef script in rootLib.scripts!) {
      if (script.uri!.contains(filename)) {
        foundScript = await service.getObject(isolateId, script.id!) as Script;
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
      );
      hits = getHitsFor(coverage, filename);
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
      );
      final localHits = getHitsFor(coverage, filename);
      expect(localHits.length, hits.length);
      expect(hits.toList()..sort(), localHits.toList()..sort());
      print(localHits);
    }
  },
];

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

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'get_source_report_const_coverage_test.dart',
      testeeConcurrent: testFunction,
    );
