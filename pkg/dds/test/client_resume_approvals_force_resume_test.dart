// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dds_service_extensions/dds_service_extensions.dart';
import 'package:vm_service/vm_service.dart';

import 'client_resume_approvals_common.dart';
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const String clientName = 'TestClient';
const String otherClientName = 'OtherTestClient';

void fooBar() {
  int i = 0;
  print(i);
}

final test = <IsolateTest>[
  // Multiple clients, different client names.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final client1 = await createClient(
      service: service,
      clientName: clientName,
      onPauseStart: true,
    );
    // ignore: unused_local_variable
    final client2 = await createClient(
      service: service,
      clientName: otherClientName,
      onPauseStart: true,
    );

    await hasPausedAtStart(service, isolateRef);
    await client1.requireUserPermissionToResume(
      onPauseStart: true,
    );

    // Invocations of `resume` are considered to be resume requests made by the
    // user and is treated as a force resume, ignoring any resume permissions
    // set by clients.
    await client1.resume(isolateId);
    await hasStoppedAtExit(service, isolateRef);
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      test,
      'client_resume_approvals_force_resume_test.dart',
      testeeConcurrent: fooBar,
      pauseOnStart: true,
      pauseOnExit: true,
    );
