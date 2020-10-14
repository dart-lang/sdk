// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'client_resume_approvals_common.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

Future testMain() async {
  // Log a total of 9 messages
  for (int i = 1; i <= 9; ++i) {
    log('log$i');
  }
  debugger();
  log('log10');
}

Future setLogHistorySize(Isolate isolate, int size) async {
  return await isolate.invokeRpcNoUpgrade('setLogHistorySize', {
    'size': size,
  });
}

Future<int> getLogHistorySize(Isolate isolate) async {
  final result = await isolate.invokeRpcNoUpgrade('getLogHistorySize', {});
  expect(result['type'], 'Size');
  return result['size'] as int;
}

var tests = <IsolateTest>[
  isPausedAtStart,
  resumeIsolate,
  (Isolate isolate) async {
    // Check that resizing does the right thing.
    final result = await setLogHistorySize(isolate, 10);
    expect(result['type'], 'Success');
    expect(await getLogHistorySize(isolate), 10);

    final completer = Completer<void>();

    int i = 1;
    await subscribeToStream(isolate.vm, 'Logging', (event) async {
      expect(event.logRecord!['message'].valueAsString, 'log$i');
      i++;

      if (i == 10) {
        await cancelStreamSubscription('Logging');
        completer.complete();
      } else if (i > 10) {
        fail('Too many log messages');
      }
    });
    await completer.future;
  },
  (Isolate isolate) async {
    // Resize to be smaller
    final result = await setLogHistorySize(isolate, 5);
    expect(result['type'], 'Success');
    expect(await getLogHistorySize(isolate), 5);
  },
  resumeIsolate,
  (Isolate isolate) async {
    final completer = Completer<void>();

    // Create a new client as we want to get log messages from the entire
    // history buffer.
    final client = await createClient(isolate.vm as WebSocketVM);

    int i = 6;
    await subscribeToStream(client, 'Logging', (event) async {
      expect(event.logRecord!['message'].valueAsString, 'log$i');
      i++;

      if (i == 11) {
        await cancelStreamSubscription('Logging');
        completer.complete();
      } else if (i > 11) {
        fail('Too many log messages');
      }
    });
    await completer.future;
    client.disconnect();
  },
];

main(args) => runIsolateTests(
      args,
      tests,
      enableService: false, // DDS specific feature
      testeeConcurrent: testMain,
      pause_on_start: true,
      pause_on_exit: true,
    );
