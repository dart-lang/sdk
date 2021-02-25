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
  while (true) {
    i++;
  }
  print(i);
}

WebSocketVM client1;
WebSocketVM client2;

final hotReloadTest = <IsolateTest>[
  // Multiple clients, hot reload approval.
  (Isolate isolate) async {
    final resumeFuture = waitForResume(isolate);

    client1 = await createClient(isolate.owner);
    await setRequireApprovalForResume(
      client1,
      isolate,
      pauseOnReload: true,
    );
    client2 = await createClient(
      isolate.owner,
      clientName: otherClientName,
    );
    await setRequireApprovalForResume(
      client2,
      isolate,
      pauseOnReload: true,
    );
  },
  // Paused on start, resume.
  resumeIsolate,
  // Reload and then pause.
  reloadSources(true),
  hasStoppedPostRequest,
  (Isolate isolate) async {
    // Check that client2 can't resume the isolate on its own.
    expect(await isPausedPostRequest(isolate), true);
    await resume(client2, isolate);
    expect(await isPausedPostRequest(isolate), true);
    final resumeFuture = waitForResume(isolate);
    await resume(client1, isolate);
    await resumeFuture;
    expect(await isPausedPostRequest(isolate), false);
  },
];

Future<void> main(args) => runIsolateTests(
      args,
      hotReloadTest,
      testeeConcurrent: fooBar,
      pause_on_start: true,
      enableService: false,
    );
