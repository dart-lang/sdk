// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dds_service_extensions/dds_service_extensions.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import 'client_resume_approvals_common.dart';
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const String clientName = 'TestClient';
const String otherClientName = 'OtherTestClient';
const String dummyClientName = 'DummyClient';

void fooBar() {
  int i = 0;
  print(i);
}

final test = <IsolateTest>[
  // Remove required approvals via name change.
  (VmService service, IsolateRef isolateRef) async {
    service.requireUserPermissionToResume(onPauseStart: false);
    final isolateId = isolateRef.id!;

    // Create two clients with the same name.
    final client1 = await createClient(
      service: service,
      clientName: clientName,
      onPauseStart: true,
    );
    // Don't use the helper so we don't call `requirePermissionToResume`
    final client2 = await vmServiceConnectUri(service.wsUri!);
    await client2.setClientName(clientName);

    final client3 = await createClient(
      service: service,
      clientName: otherClientName,
    );

    // Check that client3 can't resume the isolate on its own.
    await hasPausedAtStart(service, isolateRef);
    await client3.readyToResume(isolateId);
    await hasPausedAtStart(service, isolateRef);

    // Change the name of client1. Since client2 has the same name that client1
    // originally had, the service still requires approval to resume the
    // isolate.
    await client1.setClientName('foobar');
    await hasPausedAtStart(service, isolateRef);
    await client2.setClientName('baz');
  },
  hasStoppedAtExit,
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      test,
      'client_resume_approvals_name_change_test.dart',
      testeeConcurrent: fooBar,
      pauseOnStart: true,
      pauseOnExit: true,
    );
