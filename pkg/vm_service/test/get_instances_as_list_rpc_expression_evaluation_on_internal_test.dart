// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    late final bool gotError;

    Future<void> getInstancesAndExecuteExpression(ClassHeapStats member) async {
      final result = await service.getInstancesAsList(
        isolateId,
        member.classRef!.id!,
        includeSubclasses: false,
        includeImplementers: false,
      );
      // This has previously caused an exception like
      // 'ServerRpcException(evaluate: Unexpected exception: FormatException:
      // Unexpected character (at offset 329)'
      await service.evaluate(isolateId, result.id!, 'this').catchError((error) {
        if (error.code == 113 &&
            error.message == 'Expression compilation error' &&
            error.details.contains(
              "invalid 'targetId' parameter: Cannot evaluate against a VM-internal object",
            )) {
          gotError = true;
          return Response();
        } else {
          throw 'Got error $error but expected another message.';
        }
      });
    }

    final result = await service.getAllocationProfile(isolateId);
    for (final member in result.members!) {
      final name = member.classRef!.name!;
      if (name == 'Library') {
        await getInstancesAndExecuteExpression(member);
      }
    }
    if (!gotError) {
      throw "Didn't get expected error!";
    }
  }
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'get_instances_as_list_rpc_expression_evaluation_on_internal_test.dart',
    );
