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
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
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

    await hasPausedAtStart(service, isolateRef);

    // When one client indicates that it's ready to resume, DDS waits to resume
    // until the other client indicates it's ready.
    await client2.readyToResume(isolateId);
    await hasPausedAtStart(service, isolateRef);

    // If the only remaining client changes their resume permissions, DDS
    // should check if the isolate should be resumed. In this case, the only
    // other client requiring permission to resume has indicated that it's
    // ready, so the isolate is resumed and pauses at exit.
    // [requireUserPermissionToResume] must be called in addition to
    // [requirePermissionToResume], because the testee is started with
    // --pause-isolates-on-start, which makes DDS's
    // [IsolateManager._determineRequireUserPermissionToResumeFromFlags] require
    // clients to have user permission to resume.
    await client1.requirePermissionToResume(onPauseStart: false);
    await client1.requireUserPermissionToResume(onPauseStart: false);
    await hasStoppedAtExit(service, isolateRef);
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      test,
      'client_resume_approvals_no_longer_require_permission_test.dart',
      testeeConcurrent: fooBar,
      pauseOnStart: true,
      pauseOnExit: true,
    );
