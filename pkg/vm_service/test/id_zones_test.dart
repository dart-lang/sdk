// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

final tests = <IsolateTest>[
  // TODO(derekxu16): Replace the usages of [callMethod] below with calls to
  // dedicated RPC methods once they're available in package:vm_service.
  (VmService service, IsolateRef isolateRef) async {
    // Test the behaviour of an ID Zone with a `backingBufferKind` of `Ring` and
    // an `idAssignmentPolicy` of `AlwaysAllocate`.
    final isolateId = isolateRef.id!;
    final idZone1 = (await service.callMethod(
      '_createIdZone',
      isolateId: isolateId,
      args: {
        'backingBufferKind': 'Ring',
        'idAssignmentPolicy': 'AlwaysAllocate',
      },
    ))
        .json!;
    expect(idZone1['type'], '_IdZone');
    expect(idZone1['id'], 'zones/1');
    expect(idZone1['backingBufferKind'], 'Ring');
    expect(idZone1['idAssignmentPolicy'], 'AlwaysAllocate');

    // Test the behaviour of an ID Zone with a `backingBufferKind` of `Ring` and
    // an `idAssignmentPolicy` of `ReuseExisting`.
    final idZone2 = (await service.callMethod(
      '_createIdZone',
      isolateId: isolateId,
      args: {
        'backingBufferKind': 'Ring',
        'idAssignmentPolicy': 'ReuseExisting',
      },
    ))
        .json!;
    expect(idZone2['type'], '_IdZone');
    expect(idZone2['id'], 'zones/2');
    expect(idZone2['backingBufferKind'], 'Ring');
    expect(idZone2['idAssignmentPolicy'], 'ReuseExisting');
  },
];

Future<void> main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'id_zones_test.dart',
    );
