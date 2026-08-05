// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'rewind_optimized_out_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('rewind_optimized_out_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_0')
        .stepOver()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final isolate = await service.getIsolate(isolateId);

      // We are at our breakpoint with global=100.
      final result = await service.evaluate(
        isolateId,
        isolate.libraries!
            .firstWhere((l) => l.uri!.contains('rewind_optimized_out_lib'))
            .id!,
        'global',
      ) as InstanceRef;
      expect(result.valueAsString, '100');

      // Rewind the top stack frame.
      bool caughtException = false;
      try {
        await service.resume(isolateId, step: StepOption.kRewind);
        fail('Unreachable');
      } on RPCError catch (e) {
        caughtException = true;
        expect(e.code, RPCErrorKind.kIsolateCannotBeResumed.code);
        expect(
          e.details,
          startsWith('Cannot rewind to frame 1 due to conflicting compiler '
              'optimizations. Run the vm with --no-prune-dead-locals '
              'to disallow these optimizations. Next valid rewind '
              'frame is '),
        );
      }
      expect(caughtException, true);
    }).run(
      testeeMain: testee_lib.main,
      extraArgs: [
        '--trace-rewind',
        '--prune-dead-locals',
        '--no-background-compilation',
        '--optimization-counter-threshold=10',
      ],
    );
