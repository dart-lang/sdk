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
        // Start of main.
        .stoppedAtLine('LINE_A')
        // Add breakpoint
        .addCustomTestWithParser((
          VmService service,
          IsolateRef isolateRef,
          TestScriptParser parser,
        ) async {
          final isolateId = isolateRef.id!;
          final rootLib = await service.getObject(
              isolateId,
              (await service.getIsolate(isolateId))
                  .libraries!
                  .firstWhere(
                      (l) => l.uri!.contains('debugging_inlined_finally_lib'))
                  .id!) as Library;

          final scriptId = rootLib.scripts![0].id!;
          final script = await service.getObject(isolateId, scriptId) as Script;

          int addedBreakpoints = 0;
          Future<void> addBreakpoint(int line) async {
            final bpt =
                await service.addBreakpoint(isolateId, script.id!, line);
            addedBreakpoints += 1;

            expect(bpt.location!.script!.id, scriptId);
            expect(
              script.getLineNumberFromTokenPos(bpt.location!.tokenPos),
              line,
            );

            final isolate = await service.getIsolate(isolateId);
            expect(isolate.breakpoints!.length, addedBreakpoints);
          }

          final lines = [
            parser.lineForTag('LINE_B'),
            parser.lineForTag('LINE_C'),
            parser.lineForTag('LINE_D'),
            parser.lineForTag('LINE_E'),
            parser.lineForTag('LINE_F'),
          ];
          for (final line in lines) {
            await addBreakpoint(line);
          }
        })
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        // Normal return.
        .stoppedAtLine('LINE_B')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        // Inner finally clause.
        .stoppedAtLine('LINE_C')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        // Outer finally clause.
        .stoppedAtLine('LINE_D')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        // Exceptional return.
        .stoppedAtLine('LINE_E')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        // Inner finally clause.
        .stoppedAtLine('LINE_C')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        // Outer finally clause.
        .stoppedAtLine('LINE_D')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        // Exit from outer finally block
        .stoppedAtLine('LINE_F')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        // Outer finally clause.
        .stoppedAtLine('LINE_D')
        .resumeIsolate()
        .run(testeeMain: testee_lib.main);
