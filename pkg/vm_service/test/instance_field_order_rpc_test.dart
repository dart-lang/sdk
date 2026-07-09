// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'instance_field_order_rpc_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('instance_field_order_rpc_lib.dart', args)
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final isolate = await service.getIsolate(isolateId);
      // Call eval to get a Dart list.
      final evalResult = await service.invoke(
        isolateId,
        isolate.libraries!
            .firstWhere((l) => l.uri!.contains('instance_field_order_rpc_lib'))
            .id!,
        'getSub',
        [],
      ) as InstanceRef;
      final result = await service.getObject(
        isolateId,
        evalResult.id!,
      ) as Instance;

      expect(result.kind, InstanceKind.kPlainInstance);
      expect(result.classRef!.name, 'Sub');
      expect(result.size, isPositive);
      final fields = result.fields!;
      expect(fields.length, 4);
      expect(fields[0].decl!.name, 'z');
      expect(fields[0].value.valueAsString, '1');
      expect(fields[1].decl!.name, 'y');
      expect(fields[1].value.valueAsString, '2');
      expect(fields[2].decl!.name, 'y');
      expect(fields[2].value.valueAsString, '3');
      expect(fields[3].decl!.name, 'x');
      expect(fields[3].value.valueAsString, '4');
    }).run(testeeMain: testee_lib.main);
