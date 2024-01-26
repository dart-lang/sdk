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

const kMaxLogHistorySize = 100000;
const kExpectedMaxLogIndex = kMaxLogHistorySize + 10;

void testMain() {
  // Log a total of 100,010 messages
  for (int i = 1; i <= kExpectedMaxLogIndex; i++) {
    log('All work and no play makes Ben a dull boy ($i)');
  }
  debugger();
}

final tests = <IsolateTest>[
  hasPausedAtStart,
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final initialSize = (await service.getLogHistorySize(isolateId)).size;
    try {
      await service.setLogHistorySize(isolateId, kMaxLogHistorySize + 1);
    } on RPCError catch (e) {
      expect(e.message, "'size' must be less than $kMaxLogHistorySize");
    }
    expect((await service.getLogHistorySize(isolateId)).size, initialSize);
  },
  (VmService service, IsolateRef isolateRef) async {
    await service.setLogHistorySize(isolateRef.id!, kMaxLogHistorySize);
    expect(
      (await service.getLogHistorySize(isolateRef.id!)).size,
      kMaxLogHistorySize,
    );
  },
  resumeIsolate,
  // Wait for the process to finish logging
  hasStoppedAtBreakpoint,
  (VmService service, IsolateRef isolateRef) async {
    final completer = Completer<void>();
    // We've logged kMaxLogHistorySize + 10 messages, but we only expect to
    // receive kMaxLogHistorySize logs..
    int i = 11;
    service.onLoggingEvent.listen((event) async {
      expect(
        event.logRecord!.message!.valueAsString,
        'All work and no play makes Ben a dull boy ($i)',
      );
      if (i == kExpectedMaxLogIndex) {
        await service.streamCancel(EventStreams.kLogging);
        completer.complete();
      }
      i++;
    });
    // Subscribing to the Logging stream will cause all the log events to be
    // sent immediately.
    await service.streamListen(EventStreams.kLogging);
    await completer.future;
  }
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'log_history_size_gigantic_test.dart',
      testeeConcurrent: testMain,
      pauseOnStart: true,
      pauseOnExit: true,
    );
