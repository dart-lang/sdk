// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'get_instances_as_array_rpc_lib.dart' as testee_lib;

void main([args = const <String>[]]) =>
    IsolateTestHarness('get_instances_as_array_rpc_lib.dart', args)
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;
      final isolate = await service.getIsolate(isolateId);
      final rootLibId = isolate.libraries!
          .firstWhere((l) => l.uri!.contains('get_instances_as_array_rpc_lib'))
          .id!;
      final rootLib = await service.getObject(isolateId, rootLibId) as Library;

      Future<void> invoke(String selector) => service.invoke(
            isolateId,
            rootLibId,
            selector,
            const <String>[],
          );

      Future<int> instanceCount(
        String className, {
        bool includeSubclasses = false,
        bool includeImplementors = false,
      }) async {
        final objectId =
            rootLib.classes!.singleWhere((cls) => cls.name == className).id!;
        final result = await service.getInstancesAsList(
          isolateId,
          objectId,
          includeImplementers: includeImplementors,
          includeSubclasses: includeSubclasses,
        );
        return result.length!;
      }

      expect(await instanceCount('Class'), 0);
      expect(await instanceCount('Class', includeSubclasses: true), 0);
      expect(await instanceCount('Class', includeImplementors: true), 0);

      await invoke('allocate');

      expect(await instanceCount('Class'), 1);
      expect(await instanceCount('Class', includeSubclasses: true), 2);
      expect(await instanceCount('Class', includeImplementors: true), 3);
    }).run(testeeMain: testee_lib.main);
