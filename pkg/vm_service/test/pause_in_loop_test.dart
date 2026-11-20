// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that pausing an isolate running a loop without calls reports the
// location of the loop, where the isolate checks for interrupts, and the
// local variables visible there, even though that check is not a pause point
// for stepping.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'pause_in_loop_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('pause_in_loop_lib.dart', args)
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          final isolateId = isolateRef.id!;
          final isolate = await service.getIsolate(isolateId);
          final interrupted = hasPausedFor(
            service,
            isolate,
            EventKind.kPauseInterrupted,
          );
          await service.pause(isolateId);
          await interrupted;
        })
        .stoppedAtLine('LINE_A')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          final isolateId = isolateRef.id!;
          final stack = await service.getStack(isolateId);
          final frame = stack.frames!.first;
          final location = frame.location!;
          expect(location.tokenPos, isNonNegative);
          expect(location.line, isNotNull);
          expect(location.column, isNotNull);
          expect(frame.vars!.map((v) => v.name), contains('count'));

          final result = await service.evaluateInFrame(isolateId, 0, 'count');
          expect(result, isA<InstanceRef>());
          expect((result as InstanceRef).kind, InstanceKind.kInt);
        })
        .run(testeeMain: testee_lib.main);
