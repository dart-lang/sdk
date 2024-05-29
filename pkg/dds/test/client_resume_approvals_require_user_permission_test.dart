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
      onPauseExit: true,
    );
    final client2 = await createClient(
      service: service,
      clientName: otherClientName,
      onPauseStart: true,
      onPauseExit: true,
    );

    await hasPausedAtStart(service, isolateRef);
    await client1.requireUserPermissionToResume(
      onPauseStart: true,
      onPauseExit: true,
    );

    // Both clients indicate they're ready to resume but the isolate won't
    // resume until `resume` is invoked to indicate the user has triggered a
    // resume.
    await client2.readyToResume(isolateId);
    await hasPausedAtStart(service, isolateRef);
    await client1.readyToResume(isolateId);
    await hasPausedAtStart(service, isolateRef);

    // Indicate the user is ready to resume and the isolate should run to
    // completion.
    await client1.resume(isolateId);
    await hasStoppedAtExit(service, isolateRef);

    // Both clients indicate they're ready to resume but the isolate won't
    // resume until `resume` is invoked to indicate the user has triggered a
    // resume.
    await client2.readyToResume(isolateId);
    await hasStoppedAtExit(service, isolateRef);
    await client1.readyToResume(isolateId);
    await hasStoppedAtExit(service, isolateRef);

    await client1.resume(isolateId);
    // We can't verify the process actually resumes with this test harness, so
    // we're going to assume it did.
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      test,
      'client_resume_approvals_require_user_permission_test.dart',
      testeeConcurrent: fooBar,
      pauseOnStart: true,
      pauseOnExit: true,
    );
