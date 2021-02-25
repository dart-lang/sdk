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

final test = <IsolateTest>[
  hasPausedAtStart,
  (Isolate isolate) async {
    client1 = await createClient(isolate.owner as WebSocketVM);
    await setRequireApprovalForResume(
      client1,
      isolate,
      pauseOnStart: true,
      pauseOnExit: true,
    );
    client2 = await createClient(
      isolate.owner as WebSocketVM,
      clientName: otherClientName,
    );
    await setRequireApprovalForResume(
      client2,
      isolate,
      pauseOnStart: true,
      pauseOnExit: true,
    );

    // Give resume approval for client1 to ensure approval state is cleaned up
    // properly when both client1 and client2 have disconnected.
    await resume(client1, isolate);
    expect(await isPausedAtStart(isolate), true);

    // Once client1 is disconnected, we should still be paused.
    client1.disconnect();
    expect(await isPausedAtStart(isolate), true);

    // Once client2 disconnects, there are no clients which require resume
    // approval. Since there were no resume requests made by clients which are
    // still connected, the isolate remains paused.
    client2.disconnect();
    expect(await isPausedAtStart(isolate), true);

    await isolate.resume();
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
