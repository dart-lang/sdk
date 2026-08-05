// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'regress_34841_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('regress_34841_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final isolate = await service.getIsolate(isolateId);
      final rootLib = await service.getObject(
        isolateId,
        isolate.libraries!
            .firstWhere((l) => l.uri!.contains('regress_34841_lib'))
            .id!,
      ) as Library;
      final script = await service.getObject(
        isolateId,
        rootLib.scripts!.first.id!,
      ) as Script;

      final report = await service.getSourceReport(
        isolateId,
        [SourceReportKind.kCoverage],
        scriptId: script.id!,
        forceCompile: true,
      );

      final ranges = report.ranges!;
      final coveragePlaces = <int>[];
      for (final range in ranges) {
        final coverage = range.coverage!;
        for (int i in coverage.hits!) {
          coveragePlaces.add(i);
        }
        for (int i in coverage.misses!) {
          coveragePlaces.add(i);
        }
      }
      expect(ranges, isNotEmpty);

      // Make sure we can translate it all.
      for (int place in coveragePlaces) {
        final int? line = script.getLineNumberFromTokenPos(place);
        final int? column = script.getColumnNumberFromTokenPos(place);
        if (line == null || column == null) {
          throw 'Token $place translated to $line:$column';
        }
      }
    }).run(testeeMain: testee_lib.main);
