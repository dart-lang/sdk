// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'common/service_test_common.dart';
import 'developer_service_get_isolate_id_lib.dart' as testee_lib;

// tester state:
late IsolateRef initialIsolate;
late IsolateRef localChildIsolate;

void main([args = const <String>[]]) =>
    VMTestHarness('developer_service_get_isolate_id_lib.dart', args)
        .addTest((VmService service) async {
      final vm = await service.getVM();
      // Sanity check.
      expect(vm.isolates!.length, 1);
      initialIsolate = vm.isolates![0];
      await hasStoppedAtBreakpoint(service, initialIsolate);
      // Resume.
      await service.resume(initialIsolate.id!);
    }).addTest((VmService service) async {
      // Initial isolate has paused at second debugger call.
      await hasStoppedAtBreakpoint(service, initialIsolate);
    }).addTest((VmService service) async {
      final vm = await service.getVM();

      // Grab the child isolate.
      localChildIsolate =
          vm.isolates!.firstWhere((IsolateRef i) => i != initialIsolate);
      expect(localChildIsolate, isNotNull);

      // Reload the initial isolate.
      initialIsolate = await service.getIsolate(initialIsolate.id!);

      // Grab the root library.
      final Library rootLib = await service.getObject(
        initialIsolate.id!,
        (initialIsolate as Isolate)
            .libraries!
            .firstWhere(
                (l) => l.uri!.contains('developer_service_get_isolate_id_lib'))
            .id!,
      ) as Library;

      // Grab self id.
      final localSelfId = await service.invoke(
        initialIsolate.id!,
        rootLib.id!,
        'getSelfId',
        [],
      ) as InstanceRef;

      // Check that the id reported from dart:loper matches the id reported
      // from the service protocol.
      expect(localSelfId.kind, InstanceKind.kString);
      expect(initialIsolate.id, localSelfId.valueAsString);

      // Grab the child isolate's id.
      final localChildId = await service.invoke(
        initialIsolate.id!,
        rootLib.id!,
        'getChildId',
        [],
      ) as InstanceRef;

      // Check that the id reported from dart:loper matches the id reported
      // from the service protocol.
      expect(localChildId.kind, InstanceKind.kString);
      expect(localChildIsolate.id, localChildId.valueAsString);
    }).run(testeeMain: testee_lib.main);
