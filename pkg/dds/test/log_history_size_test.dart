// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'package:dds_service_extensions/dds_service_extensions.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

void testMain() {
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

late final String isolateId;

final tests = <IsolateTest>[
  hasPausedAtStart,
  (VmService service, IsolateRef isolateRef) async {
    isolateId = isolateRef.id!;
    await service.setLogHistorySize(isolateId, 0);
    expect((await service.getLogHistorySize(isolateId)).size, 0);
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  (VmService service, IsolateRef isolateRef) async {
    await service.setLogHistorySize(isolateId, 20);
    expect((await service.getLogHistorySize(isolateId)).size, 20);
  },
  resumeIsolate,
  (VmService service, IsolateRef isolateRef) async {
    final completer = Completer<void>();

    await Future.delayed(const Duration(seconds: 1));

    // With the log history set to 20, the first log message should be 'log11'.
    int i = 11;
    service.onLoggingEvent.listen((event) async {
      expect(event.logRecord!.message!.valueAsString, 'log$i');
      i++;

      if (i == 30) {
        await service.streamCancel(EventStreams.kLogging);
        completer.complete();
      }
    });
    await service.streamListen(EventStreams.kLogging);
    await completer.future;
  },
  (VmService service, IsolateRef isolateRef) async {
    try {
      // Try to set an invalid history size
      await service.setLogHistorySize(isolateId, -1);
      fail('Successfully set invalid size');
    } on RPCError catch (e) {
      expect(e.message, "'size' must be greater or equal to zero");
    }
    expect((await service.getLogHistorySize(isolateId)).size, 20);
  }
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'log_history_size_test.dart',
      testeeConcurrent: testMain,
      pauseOnStart: true,
      pauseOnExit: true,
    );
