// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

Future testMain() async {
  // Initial logging history should be 0, so these messages won't be buffered.
  log('log1');
  log('log2');

  // Setting the log history length does not apply retroactively.
  debugger();

  // Log a total of 30 messages
  for (int i = 3; i <= 30; ++i) {
    log('log$i');
  }
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
  hasPausedAtStart,
  (Isolate isolate) async {
    final result = await setLogHistorySize(isolate, 0);
    expect(result['type'], 'Success');
    expect(await getLogHistorySize(isolate), 0);
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    final result = await setLogHistorySize(isolate, 20);
    expect(await getLogHistorySize(isolate), 20);
    expect(result['type'], 'Success');
  },
  resumeIsolate,
  (Isolate isolate) async {
    final completer = Completer<void>();

    await Future.delayed(const Duration(seconds: 1));

    // With the log history set to 20, the first log message should be 'log11'
    int i = 11;
    await subscribeToStream(isolate.vm, 'Logging', (event) async {
      expect(event.logRecord!['message'].valueAsString, 'log$i');
      i++;

      if (i == 30) {
        await cancelStreamSubscription('Logging');
        completer.complete();
      }
    });
    await completer.future;
  },
  (Isolate isolate) async {
    try {
      // Try to set an invalid history size
      await setLogHistorySize(isolate, -1);
      fail('Successfully set invalid size');
    } on ServerRpcException catch (e) {
      expect(e.message, "'size' must be greater or equal to zero");
    }
    expect(await getLogHistorySize(isolate), 20);
  }
];

main(args) => runIsolateTests(
      args,
      tests,
      enableService: false, // DDS specific feature
      testeeConcurrent: testMain,
      pause_on_start: true,
      pause_on_exit: true,
    );
