// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import 'common/service_test_common.dart';

Future _checkZone(isolateId, client, idZone) async {
  final result = await client.evaluateInFrame(
    isolateId,
    0,
    'abcString',
    idZoneId: idZone.id,
  );
  await client.callMethod('_collectAllGarbage', isolateId: isolateId);
  await client.getObject(isolateId, result.id, idZoneId: idZone.id);
}

IsolateTestHarness createHarness(List<String> args) => IsolateTestHarness(
      'id_zone_deletion_on_client_disconnect_lib.dart',
      args,
    )
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest((VmService client1, IsolateRef isolateRef) async {
      final isolateId = isolateRef.id!;

      final idZone1 = await client1.createIdZone(
        isolateId,
        IdZoneBackingBufferKind.kRing,
        IdAssignmentPolicy.kAlwaysAllocate,
      );

      // Confirm that [idZone1] can be used.
      await _checkZone(isolateId, client1, idZone1);

      final client2 = await vmServiceConnectUri(client1.wsUri!);
      final idZone2 = await client2.createIdZone(
        isolateId,
        IdZoneBackingBufferKind.kRing,
        IdAssignmentPolicy.kAlwaysAllocate,
      );

      // Confirm that [idZone2] can be used.
      await _checkZone(isolateId, client2, idZone2);

      // Disposing of [client2] should delete [idZone2];
      await client2.dispose();

      // Confirm that [idZone2] can be no longer be used.
      try {
        await _checkZone(isolateId, client1, idZone2);
        fail('successfully used an ID zone that should have been deleted');
      } on RPCError catch (e) {
        expect(e.code, RPCErrorKind.kInvalidParams.code);
      }

      // Confirm that [idZone1] can still be used.
      await _checkZone(isolateId, client1, idZone1);
    });
