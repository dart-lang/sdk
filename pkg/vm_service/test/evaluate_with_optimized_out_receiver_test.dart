// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that expressions can be evaluated in the context of a closure
// inside an instance method when the closure does not capture the receiver,
// as long as the expression does not use the receiver.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'evaluate_with_optimized_out_receiver_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('evaluate_with_optimized_out_receiver_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;

      // Doesn't use the receiver, so evaluates even though it is unavailable.
      final result = await service.evaluateInFrame(
        isolateId,
        0,
        'innerParam + innerTemp',
      );
      expect((result as InstanceRef).valueAsString, '13');

      // Uses the receiver, which is unavailable.
      try {
        await service.evaluateInFrame(isolateId, 0, 'instVar');
        fail('successfully evaluated an expression using the receiver');
      } on SentinelException catch (e) {
        expect(e.sentinel.kind, SentinelKind.kOptimizedOut);
      }
    }).run(testeeMain: testee_lib.main);
