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

final sameClientNamesTest = <IsolateTest>[
  // Multiple clients, same client names.
  (Isolate isolate) async {
    final resumeFuture = waitForResume(isolate);

    client1 = await createClient(isolate.owner as WebSocketVM);
    await setRequireApprovalForResume(
      client1,
      isolate,
      pauseOnStart: true,
      pauseOnExit: true,
    );
    client2 = await createClient(isolate.owner as WebSocketVM);

    expect(await isPausedAtStart(isolate), true);
    await resume(client2, isolate);
    await resumeFuture;
  },
  hasStoppedAtExit,
];

Future<void> main(args) => runIsolateTests(
      args,
      sameClientNamesTest,
      testeeConcurrent: fooBar,
      pause_on_start: true,
      pause_on_exit: true,
      enableService: false,
    );
