// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'rewind_lib.dart' as testee_lib;

void main([args = const <String>[]]) => IsolateTestHarness(
      'rewind_lib.dart',
      args,
    )
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_0')
        .stepOver()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          final isolateId = isolateRef.id!;
          // We are not able to rewind frame 0.
          bool caughtException = false;
          try {
            await service.resume(
              isolateId,
              step: StepOption.kRewind,
              frameIndex: 0,
            );
            fail('Unreachable');
          } on RPCError catch (e) {
            caughtException = true;
            expect(e.code, RPCErrorKind.kIsolateCannotBeResumed.code);
            expect(e.details, 'Frame must be in bounds [1..11]: saw 0');
          }
          expect(caughtException, true);
        })
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          final isolateId = isolateRef.id!;
          // We are not able to rewind frame 13.
          bool caughtException = false;
          try {
            await service.resume(
              isolateId,
              step: StepOption.kRewind,
              frameIndex: 13,
            );
            fail('Unreachable');
          } on RPCError catch (e) {
            caughtException = true;
            expect(e.code, RPCErrorKind.kIsolateCannotBeResumed.code);
            expect(e.details, 'Frame must be in bounds [1..11]: saw 13');
          }
          expect(caughtException, true);
        })
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          final isolateId = isolateRef.id!;
          final isolate = await service.getIsolate(isolateId);
          final rootLibId = isolate.libraries!
              .firstWhere((l) => l.uri!.contains('rewind_lib'))
              .id!;

          // We are at our breakpoint with global=100.
          final result = await service.evaluate(
            isolateId,
            rootLibId,
            'global',
          ) as InstanceRef;
          print('global is $result');
          expect(result.valueAsString, '100');

          // Rewind the top stack frame.
          await service.resume(isolateId,
              step: StepOption.kRewind, frameIndex: 1);
        })
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_0')
        .stepOver()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          final isolateId = isolateRef.id!;
          final isolate = await service.getIsolate(isolateId);
          final rootLibId = isolate.libraries!
              .firstWhere((l) => l.uri!.contains('rewind_lib'))
              .id!;

          // global still is equal to 100.  We did not execute 'global++'.
          final result = await service.evaluate(
            isolateId,
            rootLibId,
            'global',
          ) as InstanceRef;
          print('global is $result');
          expect(result.valueAsString, '100');

          // Rewind up to 'test'/
          await service.resume(isolateId,
              step: StepOption.kRewind, frameIndex: 3);
        })
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_D')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          final isolateId = isolateRef.id!;
          final isolate = await service.getIsolate(isolateId);
          final rootLibId = isolate.libraries!
              .firstWhere((l) => l.uri!.contains('rewind_lib'))
              .id!;

          // Reset global to 0 and start again.
          final result = await service.evaluate(
            isolateId,
            rootLibId,
            'global = 0',
          ) as InstanceRef;
          expect(result.valueAsString, '0');
        })
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_0')
        .stepOver()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          final isolateId = isolateRef.id!;
          final isolate = await service.getIsolate(isolateId);
          final rootLibId = isolate.libraries!
              .firstWhere((l) => l.uri!.contains('rewind_lib'))
              .id!;

          // We are at our breakpoint with global=100.
          final result = await service.evaluate(
            isolateId,
            rootLibId,
            'global',
          ) as InstanceRef;
          print('global is $result');
          expect(result.valueAsString, '100');

          // Rewind the top 2 stack frames.
          await service.resume(isolateId,
              step: StepOption.kRewind, frameIndex: 2);
        })
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_C')
        .run(
          testeeMain: testee_lib.main,
          extraArgs: [
            '--trace-rewind',
            '--no-prune-dead-locals',
            '--no-background-compilation',
            '--optimization-counter-threshold=10',
          ],
        );
