// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

void testMain() {
  // Log a total of 9 messages
  for (int i = 1; i <= 9; ++i) {
    print('Stdout log$i');
    stderr.writeln('Stderr log$i');
  }
}

Future<void> streamHistoryTest(
  VmService service,
  IsolateRef isolateRef,
  String stream,
) async {
  final completer = Completer<void>();
  int i = 1;
  service.onEvent(stream).listen((event) async {
    final string = decodeBase64(event.bytes!);
    if (stream == EventStreams.kStdout) {
      if (!string.startsWith(stream)) {
        // Likely "The Dart VM service is listening..." or one of the other
        // messages printed when the VM service is enabled.
        return;
      }
      expect(string, '$stream log$i\n');
    } else {
      // Newlines are sent as separate events for some reason. Ignore them.
      if (!string.startsWith(stream)) {
        return;
      }
      expect(string, '$stream log$i');
    }
    i++;

    if (i == 10) {
      await service.streamCancel(stream);
      completer.complete();
    } else if (i > 10) {
      fail('Too many log messages');
    }
  });
  await service.streamListen(stream);
  await completer.future;
}

final tests = <IsolateTest>[
  hasPausedAtStart,
  resumeIsolate,
  (VmService service, IsolateRef isolateRef) async {
    await streamHistoryTest(service, isolateRef, EventStreams.kStdout);
  },
  (VmService service, IsolateRef isolateRef) async {
    await streamHistoryTest(service, isolateRef, EventStreams.kStderr);
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'stdout_stderr_history_test.dart',
      testeeConcurrent: testMain,
      pauseOnStart: true,
      pauseOnExit: true,
    );
