// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'get_instances_as_array_rpc_expression_evaluation_on_internal_lib.dart'
    as testee_lib;

void main([args = const <String>[]]) => IsolateTestHarness(
      'get_instances_as_array_rpc_expression_evaluation_on_internal_lib.dart',
      args,
    ).addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;

      Future<void> getInstancesAndExecuteExpression(
        ClassHeapStats member,
      ) async {
        final objectId = member.classRef!.id!;
        final result = await service.getInstancesAsList(isolateId, objectId);
        // This has previously caused an exception like
        // "RPCError(evaluate: Unexpected exception:
        // FormatException: Unexpected character (at offset 329)"
        try {
          await service.evaluate(isolateId, result.id!, 'this');
        } on RPCError catch (e) {
          expect(e.code, RPCErrorKind.kExpressionCompilationError.code);
          expect(
            e.details,
            contains('Cannot evaluate against a VM-internal object'),
          );
          return;
        }
        fail('Expected exception');
      }

      final result = await service.getAllocationProfile(isolateId);
      final members = result.members!;
      for (final member in members) {
        final name = member.classRef!.name!;
        if (name == 'Library') {
          await getInstancesAndExecuteExpression(member);
          break;
        }
      }
    }).run(testeeMain: testee_lib.main);
