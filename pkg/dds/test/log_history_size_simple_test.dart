// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'package:dds_service_extensions/dds_service_extensions.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

void testMain() {
  // Log a total of 9 messages
  for (int i = 1; i <= 9; ++i) {
    log('log$i');
  }
  debugger();
  log('log10');
}

final tests = <IsolateTest>[
  hasPausedAtStart,
  resumeIsolate,
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    // Check that resizing does the right thing.
    await service.setLogHistorySize(isolateId, 10);
    expect((await service.getLogHistorySize(isolateId)).size, 10);

    final completer = Completer<void>();

    int i = 1;
    service.onLoggingEvent.listen((event) async {
      expect(event.logRecord!.message!.valueAsString, 'log$i');
      i++;

      if (i == 10) {
        await service.streamCancel(EventStreams.kLogging);
        completer.complete();
      } else if (i > 10) {
        fail('Too many log messages');
      }
    });
    await service.streamListen(EventStreams.kLogging);
    await completer.future;
  },
  (VmService service, IsolateRef isolateRef) async {
    // Resize to be smaller
    final isolateId = isolateRef.id!;
    // Check that resizing does the right thing.
    await service.setLogHistorySize(isolateId, 5);
    expect((await service.getLogHistorySize(isolateId)).size, 5);
  },
  resumeIsolate,
  (VmService service, IsolateRef isolateRef) async {
    final completer = Completer<void>();

    // Create a new client as we want to get log messages from the entire
    // history buffer.
    final client = await vmServiceConnectUri(service.wsUri!);

    int i = 6;
    client.onLoggingEvent.listen((event) async {
      expect(event.logRecord!.message!.valueAsString, 'log$i');
      i++;

      if (i == 11) {
        await client.streamCancel(EventStreams.kLogging);
        completer.complete();
      } else if (i > 11) {
        fail('Too many log messages');
      }
    });
    await client.streamListen(EventStreams.kLogging);
    await completer.future;
    client.dispose();
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'log_history_size_simple_test.dart',
      testeeConcurrent: testMain,
      pauseOnStart: true,
      pauseOnExit: true,
    );
