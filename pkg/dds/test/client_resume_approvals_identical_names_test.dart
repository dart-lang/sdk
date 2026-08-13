// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dds_service_extensions/dds_service_extensions.dart';
import 'package:vm_service/vm_service.dart';

import 'client_resume_approvals_common.dart';
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const String clientName = 'TestClient';

void fooBar() {
  int i = 0;
  print(i);
}

final test = <IsolateTest>[
  // Multiple clients, same client names.
  (VmService service, IsolateRef isolateRef) async {
    service.requireUserPermissionToResume(onPauseStart: false);
    // ignore: unused_local_variable
    final client1 = await createClient(
      service: service,
      clientName: clientName,
      onPauseStart: true,
    );
    final client2 = await createClient(
      service: service,
      clientName: clientName,
    );
    await hasPausedAtStart(service, isolateRef);
    await client2.readyToResume(isolateRef.id!);
  },
  hasStoppedAtExit,
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      test,
      'client_resume_approvals_identical_names_test.dart',
      testeeConcurrent: fooBar,
      pauseOnStart: true,
      pauseOnExit: true,
    );
