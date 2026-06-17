// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'get_instances_as_list_rpc_lib.dart' as testee_lib;

IsolateTest expectInstanceCounts(
  int numInstances,
  int numInstancesWhenIncludingSubclasses,
  int numInstancesWhenIncludingImplementers,
) {
  return (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final rootLib = await service.getObject(
      isolateId,
      isolate.libraries!
          .firstWhere((l) => l.uri!.contains('get_instances_as_list_rpc_lib'))
          .id!,
    ) as Library;

    Future<int> instanceCount(
      String className, {
      bool includeSubclasses = false,
      bool includeImplementers = false,
    }) async {
      final result = await service.getInstancesAsList(
        isolateId,
        rootLib.classes!
            .singleWhere(
              (cls) => cls.name == className,
            )
            .id!,
        includeSubclasses: includeSubclasses,
        includeImplementers: includeImplementers,
      );
      expect(result.kind, InstanceKind.kList);
      return result.length!;
    }

    expect(
      await instanceCount('Class'),
      numInstances,
    );
    expect(
      await instanceCount('Class', includeSubclasses: true),
      numInstancesWhenIncludingSubclasses,
    );
    expect(
      await instanceCount('Class', includeImplementers: true),
      numInstancesWhenIncludingImplementers,
    );
  };
}

void main([args = const <String>[]]) =>
    IsolateTestHarness('get_instances_as_list_rpc_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest(expectInstanceCounts(0, 0, 0))
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .addCustomTest(expectInstanceCounts(1, 2, 3))
        .run(testeeMain: testee_lib.main);
