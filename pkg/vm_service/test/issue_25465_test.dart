// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'issue_25465_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('issue_25465_lib.dart', args)
        .hasPausedAtStart()
        // Add breakpoints.
        .addCustomTestWithParser(
          (
            VmService service,
            IsolateRef isolateRef,
            TestScriptParser parser,
          ) async {
            final lineA = parser.lineForTag('LINE_A');
            final lineB = parser.lineForTag('LINE_B');
            final isolateId = isolateRef.id!;
            final isolate = await service.getIsolate(isolateId);
            final rootLib = await service.getObject(
              isolateId,
              isolate.libraries!
                  .firstWhere((l) => l.uri!.contains('issue_25465_lib'))
                  .id!,
            ) as Library;
            final scriptId = rootLib.scripts![0].id!;

            final bpt1 =
                await service.addBreakpoint(isolateId, scriptId, lineA);
            final bpt2 =
                await service.addBreakpoint(isolateId, scriptId, lineB);
            expect(bpt1.location!.line, lineA);
            expect(bpt2.location!.line, lineB);
          },
        )
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          final isolateId = isolateRef.id!;
          final isolate = await service.getIsolate(isolateId);
          final breakpoints = isolate.breakpoints!;
          expect(breakpoints.length, 2);
          for (final bpt in isolate.breakpoints!) {
            await service.removeBreakpoint(isolateId, bpt.id!);
          }
        })
        .stepOver()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .run(testeeMain: testee_lib.main, pauseOnStart: true);
