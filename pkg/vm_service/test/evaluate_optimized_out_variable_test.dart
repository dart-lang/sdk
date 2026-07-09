// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://dartbug.com/53996.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'evaluate_optimized_out_variable_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('evaluate_optimized_out_variable_lib.dart', args)
        .hasPausedAtStart()
        .setBreakpointAtLine('LINE_A')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      try {
        final dynamic result = await service.evaluateInFrame(
          isolateId,
          1,
          'data.length',
        );
        // Check in case the variable isn't optimized out, e.g., if the code is
        // interpreted via bytecode instead of compiled to native code.
        expect(result.valueAsString, '3');
      } on RPCError catch (e) {
        expect(e.code, RPCErrorKind.kExpressionCompilationError.code);
        expect(e.message, contains('Expression compilation error'));
        expect(
          e.details,
          contains("Error: The variable 'data' "
              'is unavailable in this expression evaluation.'),
        );
      }
    }).run(
      testeeMain: testee_lib.main,
      pauseOnStart: true,
      extraArgs: const [
        '--deterministic',
        '--prune-dead-locals',
        '--optimization-counter-threshold=10',
      ],
    );
