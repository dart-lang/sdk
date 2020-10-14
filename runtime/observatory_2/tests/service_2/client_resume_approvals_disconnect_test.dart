// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';

import 'client_resume_approvals_common.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

void fooBar() {
  int i = 0;
  print(i);
}

WebSocketVM client1;
WebSocketVM client2;

final test = <IsolateTest>[
  // Multiple clients, disconnect client awaiting approval.
  hasPausedAtStart,
  (Isolate isolate) async {
    client1 = await createClient(isolate.owner);
    await setRequireApprovalForResume(
      client1,
      isolate,
      pauseOnStart: true,
      pauseOnExit: true,
    );
    client2 = await createClient(
      isolate.owner,
      clientName: otherClientName,
    );
    await setRequireApprovalForResume(
      client2,
      isolate,
      pauseOnStart: true,
      pauseOnExit: true,
    );

    // Send a resume request on the test client so we'll resume once the other
    // clients which require approval disconnect.
    await isolate.resume();
    expect(await isPausedAtStart(isolate), true);

    // Once client1 is disconnected, we should still be paused.
    client1.disconnect();
    expect(await isPausedAtStart(isolate), true);

    // Once client2 disconnects, there are no clients which require resume
    // approval. Ensure we resume immediately so we don't deadlock waiting for
    // approvals from disconnected clients.
    client2.disconnect();
  },
  hasStoppedAtExit,
];

Future<void> main(args) => runIsolateTests(
      args,
      test,
      testeeConcurrent: fooBar,
      pause_on_start: true,
      pause_on_exit: true,
      enableService: false,
    );
