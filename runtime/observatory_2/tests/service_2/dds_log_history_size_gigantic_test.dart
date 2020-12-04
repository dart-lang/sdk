// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

Future testMain() async {
  // Log a total of 30 messages
  for (int i = 1; i <= maxLogHistorySize + 10; ++i) {
    log('All work and no play makes Ben a dull boy ($i)');
  }
  debugger();
}

const maxLogHistorySize = 100000;

Future setLogHistorySize(Isolate isolate, int size) async {
  return await isolate.invokeRpcNoUpgrade('setLogHistorySize', {
    'size': size,
  });
}

Future<int> getLogHistorySize(Isolate isolate) async {
  final result = await isolate.invokeRpcNoUpgrade('getLogHistorySize', {});
  expect(result['type'], 'Size');
  return result['size'];
}

var tests = <IsolateTest>[
  hasPausedAtStart,
  (Isolate isolate) async {
    final initialSize = await getLogHistorySize(isolate);
    try {
      await setLogHistorySize(isolate, maxLogHistorySize + 1);
    } on ServerRpcException catch (e) {
      expect(e.message, "'size' must be less than $maxLogHistorySize");
    }
    expect(await getLogHistorySize(isolate), initialSize);
  },
  (Isolate isolate) async {
    final result = await setLogHistorySize(isolate, maxLogHistorySize);
    expect(result['type'], 'Success');
    expect(await getLogHistorySize(isolate), maxLogHistorySize);
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    print("Starting step 6");
    final completer = Completer<void>();

    await Future.delayed(const Duration(seconds: 1));

    int i = 11;
    await subscribeToStream(isolate.vm, 'Logging', (event) async {
      expect(
        event.logRecord['message'].valueAsString,
        'All work and no play makes Ben a dull boy ($i)',
      );
      i++;

      if (i == maxLogHistorySize + 10) {
        await cancelStreamSubscription('Logging');
        completer.complete();
      }
    });
    await completer.future;
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
