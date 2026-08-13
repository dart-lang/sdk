// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'coverage_const_field_async_closure_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('coverage_const_field_async_closure_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .addCustomTestWithParser((
          VmService service,
          IsolateRef isolateRef,
          TestScriptParser parser,
        ) async {
          final lineA = parser.lineForTag('LINE_A');
          final lineB = parser.lineForTag('LINE_B');
          final isolateId = isolateRef.id!;
          final isolate = await service.getIsolate(isolateId);
          final stack = await service.getStack(isolateId);

          // Make sure we are in the right place.
          expect(stack.frames!.length, greaterThanOrEqualTo(1));
          // Async closure of testFunction
          expect(stack.frames![0].function!.name, 'testFunction');

          final rootLib = await service.getObject(
              isolateId,
              isolate.libraries!
                  .firstWhere((l) =>
                      l.uri!.contains('coverage_const_field_async_closure_lib'))
                  .id!) as Library;
          final script = await service.getObject(
            isolateId,
            rootLib.scripts!.first.id!,
          ) as Script;

          final report = await service.getSourceReport(
            isolateId,
            ['Coverage'],
            scriptId: script.id!,
            forceCompile: true,
          );
          int match = 0;
          for (var range in report.ranges!) {
            for (int i in range.coverage!.hits!) {
              final int? line = script.getLineNumberFromTokenPos(i);
              if (line == null) {
                throw FormatException('token $i was missing source location');
              }
              // Check LINE.
              if (line == lineA || line == lineA - 3 || line == lineA - 4) {
                match = match + 1;
              }
              // _clearAsyncThreadStackTrace should have an invalid token position.
              expect(line, isNot(lineB));
            }
          }
          // Neither LINE nor Bar.field should be added into coverage.
          expect(match, 0);
        })
        .resumeIsolate()
        .run(testeeMain: testee_lib.main);
