// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'debugging_inlined_finally_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('debugging_inlined_finally_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        // Add breakpoint
        .addCustomTestWithParser((
          VmService service,
          IsolateRef isolateRef,
          TestScriptParser parser,
        ) async {
          final lineB = parser.lineForTag('LINE_B');
          final lineC = parser.lineForTag('LINE_C');
          final lineD = parser.lineForTag('LINE_D');

          final isolateId = isolateRef.id!;
          var isolate = await service.getIsolate(isolateId);
          final rootLib = await service.getObject(
              isolateId,
              isolate.libraries!
                  .firstWhere(
                      (l) => l.uri!.contains('debugging_inlined_finally_lib'))
                  .id!) as Library;

          final scriptId = rootLib.scripts![0].id!;
          final script = await service.getObject(isolateId, scriptId) as Script;

          // Add 3 breakpoints.
          {
            final bpt =
                await service.addBreakpoint(isolateId, script.id!, lineB);
            expect(bpt.location!.script!.id, scriptId);
            expect(
              script.getLineNumberFromTokenPos(bpt.location!.tokenPos),
              lineB,
            );

            isolate = await service.getIsolate(isolateId);
            expect(isolate.breakpoints!.length, 1);
          }

          {
            final bpt = await service.addBreakpoint(isolateId, scriptId, lineC);
            expect(bpt.location!.script!.id, scriptId);
            expect(
              script.getLineNumberFromTokenPos(bpt.location!.tokenPos),
              lineC,
            );

            isolate = await service.getIsolate(isolateId);
            expect(isolate.breakpoints!.length, 2);
          }

          {
            final bpt = await service.addBreakpoint(isolateId, scriptId, lineD);
            expect(bpt.location!.script!.id, scriptId);
            expect(
              script.getLineNumberFromTokenPos(bpt.location!.tokenPos),
              lineD,
            );

            isolate = await service.getIsolate(isolateId);
            expect(isolate.breakpoints!.length, 3);
          }
        })
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        // We are at the breakpoint on line LINE_B.
        .stoppedAtLine('LINE_B')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        // We are at the breakpoint on line LINE_C.
        .stoppedAtLine('LINE_C')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        // We are at the breakpoint on line LINE_D.
        .stoppedAtLine('LINE_D')
        .resumeIsolate()
        .run(testeeMain: testee_lib.main);
