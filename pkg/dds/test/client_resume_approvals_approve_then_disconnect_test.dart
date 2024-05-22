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
  hasPausedAtStart,
  (VmService service, IsolateRef isolate) async {
    service.requireUserPermissionToResume(onPauseStart: false);
    final isolateId = isolate.id!;
    final client1 = await createClient(
      service: service,
      clientName: clientName,
      onPauseStart: true,
    );

    final client2 = await createClient(
      service: service,
      clientName: otherClientName,
      onPauseStart: true,
    );

    // Give resume approval for client1 to ensure approval state is cleaned up
    // properly when both client1 and client2 have disconnected.
    await client1.readyToResume(isolateId);
    await hasPausedAtStart(service, isolate);

    // Once client1 is disconnected, we should still be paused.
    client1.dispose();
    await hasPausedAtStart(service, isolate);

    // Once client2 disconnects, there are no clients which require resume
    // approval. Since there were no resume requests made by clients which are
    // still connected, the isolate remains paused.
    client2.dispose();
    await hasPausedAtStart(service, isolate);

    await service.readyToResume(isolateId);
  },
  hasStoppedAtExit,
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      test,
      'client_resume_approvals_approve_then_disconnect_test.dart',
      testeeConcurrent: fooBar,
      pauseOnStart: true,
      pauseOnExit: true,
    );
