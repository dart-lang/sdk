// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';

import 'client_resume_approvals_common.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

void fooBar() {
  int i = 0;
  print(i);
}

late WebSocketVM client1;
late WebSocketVM client2;
late WebSocketVM client3;

final nameChangeTest = <IsolateTest>[
  // Remove required approvals via name change.
  (Isolate isolate) async {
    final resumeFuture = waitForResume(isolate);

    // Create two clients with the same name.
    client1 = await createClient(isolate.owner as WebSocketVM);
    client2 = await createClient(isolate.owner as WebSocketVM);
    await setRequireApprovalForResume(
      client1,
      isolate,
      pauseOnStart: true,
      pauseOnExit: true,
    );
    client3 = await createClient(isolate.owner as WebSocketVM,
        clientName: otherClientName);

    // Check that client3 can't resume the isolate on its own.
    expect(await isPausedAtStart(isolate), true);
    await resume(client3, isolate);
    expect(await isPausedAtStart(isolate), true);

    // Change the name of client1. Since client2 has the same name that client1
    // originally had, the service still requires approval to resume the
    // isolate.
    await setClientName(client1, 'foobar');
    expect(await isPausedAtStart(isolate), true);
    await setClientName(client2, 'baz');
  },
  hasStoppedAtExit,
];

Future<void> main(args) => runIsolateTests(
      args,
      nameChangeTest,
      testeeConcurrent: fooBar,
      pause_on_start: true,
      pause_on_exit: true,
      enableService: false,
    );
