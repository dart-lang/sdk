// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'get_user_level_retaining_path_rpc_lib.dart' as testee_lib;

Future<InstanceRef> invoke(
  VmService service,
  String isolateId,
  String selector,
) async {
  final isolate = await service.getIsolate(isolateId);
  return await service.invoke(
    isolateId,
    isolate.libraries!
        .firstWhere(
            (l) => l.uri!.contains('get_user_level_retaining_path_rpc_lib'))
        .id!,
    selector,
    [],
  ) as InstanceRef;
}

void main([args = const <String>[]]) =>
    IsolateTestHarness('get_user_level_retaining_path_rpc_lib.dart', args)
        // Expect a simple path through variable x instead of long path filled
        // with VM objects
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final target = await invoke(service, isolateId, 'getX');
      final result = await service.getRetainingPath(isolateId, target.id!, 100);
      final elements = result.elements!;
      expect(elements.length, 2);
      expect((elements[0].value as InstanceRef).classRef!.name, '_TestConst');
      expect((elements[1].value as FieldRef).name, 'x');
    })
        // Expect a simple path through variable fn instead of long path filled
        // with VM objects
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final target = await invoke(service, isolateId, 'getFn');
      final result = await service.getRetainingPath(isolateId, target.id!, 100);
      final elements = result.elements!;
      expect(elements.length, 2);
      expect((elements[0].value as InstanceRef).classRef!.name, '_Closure');
      expect((elements[1].value as FieldRef).name, 'fn');
    }).run(testeeMain: testee_lib.main);
