// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import '../common/service_test_common.dart';
import 'get_retained_size_rpc_lib.dart' as testee_lib;

const MB = 1 << 20;

extension on VmService {
  Future<InstanceRef> getRetainedSize(
    String isolateId,
    String targetId,
  ) async {
    return await callMethod(
      '_getRetainedSize',
      isolateId: isolateId,
      args: {
        'targetId': targetId,
      },
    ) as InstanceRef;
  }
}

void main([args = const <String>[]]) => IsolateTestHarness(
      'get_retained_size_rpc_lib.dart',
      args,
    ).addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final isolate = await service.getIsolate(isolateId);
      final rootLibId = isolate.libraries!
          .firstWhere((l) => l.uri!.contains('get_retained_size_rpc_lib'))
          .id!;

      // One instance of _TestClass retained.
      var evalResult = await service.invoke(
        isolateId,
        rootLibId,
        'invoke1',
        [],
      ) as InstanceRef;
      var result = await service.getRetainedSize(isolateId, evalResult.id!);
      expect(result.kind, InstanceKind.kInt);
      final value1 = int.parse(result.valueAsString!);
      expect(value1, isPositive);

      // Two instances of _TestClass retained.
      evalResult = await service.invoke(
        isolateId,
        rootLibId,
        'invoke2',
        [],
      ) as InstanceRef;
      result = await service.getRetainedSize(isolateId, evalResult.id!);
      expect(result.kind, InstanceKind.kInt);
      final value2 = int.parse(result.valueAsString!);
      expect(value2, isPositive);

      // Size has doubled.
      expect(value2, 2 * value1);

      // Get the retained size for class _TestClass.
      result =
          await service.getRetainedSize(isolateId, evalResult.classRef!.id!);
      expect(result.kind, InstanceKind.kInt);
      final value3 = int.parse(result.valueAsString!);
      expect(value3, isPositive);
      expect(value3, value2);

      // Target of WeakReference not retained.
      evalResult = await service.invoke(
        isolateId,
        rootLibId,
        'invoke3',
        [],
      ) as InstanceRef;
      result = await service.getRetainedSize(isolateId, evalResult.id!);
      expect(result.kind, InstanceKind.kInt);
      final value4 = int.parse(result.valueAsString!);
      expect(value4, lessThan(MB));
    }).run(testeeMain: testee_lib.main);
