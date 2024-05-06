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
  // ignore: unused_local_variable
  int i = 0;
  while (true) {
    i++;
  }
}

late VmService client1;
late VmService client2;

final test = <IsolateTest>[
  // Multiple clients, hot reload approval.
  (VmService service, IsolateRef isolateRef) async {
    client1 = await createClient(
      service: service,
      clientName: clientName,
      onPauseReload: true,
    );
    client2 = await createClient(
      service: service,
      clientName: otherClientName,
      onPauseReload: true,
    );
  },
  hasPausedAtStart,
  // Paused on start, resume.
  resumeIsolate,
  // Reload and then pause.
  reloadSources(pause: true),
  hasStoppedPostRequest,
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    // Check that client2 can't resume the isolate on its own.
    await client2.readyToResume(isolateId);
    await hasStoppedPostRequest(service, isolateRef);
    await resumeIsolate(client1, isolateRef);
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      test,
      'client_resume_approvals_reload_test.dart',
      testeeConcurrent: fooBar,
      pauseOnStart: true,
    );
