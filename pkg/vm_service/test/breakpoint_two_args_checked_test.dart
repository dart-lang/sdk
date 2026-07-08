// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'breakpoint_two_args_checked_lib.dart' as testee_lib;
import 'common/service_test_common.dart';

void main([args = const <String>[]]) =>
    IsolateTestHarness('breakpoint_two_args_checked_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        // Add breakpoints.
        .addCustomTestWithParser((
          VmService service,
          IsolateRef isolateRef,
          TestScriptParser parser,
        ) async {
          final isolateId = isolateRef.id!;
          final isolate = await service.getIsolate(isolateId);
          final Library rootLib = await service.getObject(
              isolateId,
              isolate.libraries!
                  .firstWhere(
                      (l) => l.uri!.contains('breakpoint_two_args_checked_lib'))
                  .id!) as Library;

          final script = await service.getObject(
            isolateId,
            rootLib.scripts![0].id!,
          ) as Script;
          final scriptId = script.id!;

          final lineB = parser.lineForTag('LINE_B');
          final bpt1 = await service.addBreakpoint(isolateId, scriptId, lineB);
          print(bpt1);
          expect(bpt1.resolved, isTrue);
          expect(
            script.getLineNumberFromTokenPos(bpt1.location!.tokenPos),
            equals(lineB),
          );

          final lineC = parser.lineForTag('LINE_C');
          final bpt2 = await service.addBreakpoint(isolateId, scriptId, lineC);
          print(bpt2);
          expect(bpt2.resolved, isTrue);
          expect(
            script.getLineNumberFromTokenPos(bpt2.location!.tokenPos),
            equals(lineC),
          );

          final lineD = parser.lineForTag('LINE_D');
          final bpt3 = await service.addBreakpoint(isolateId, scriptId, lineD);
          print(bpt3);
          expect(bpt3.resolved, isTrue);
          expect(
            script.getLineNumberFromTokenPos(bpt3.location!.tokenPos),
            equals(lineD),
          );
        })
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_C')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_D')
        .resumeIsolate()
        .run(testeeMain: testee_lib.main);
