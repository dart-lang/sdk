// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'client_resume_approvals_common.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

Future testMain() async {
  // Log a total of 9 messages
  for (int i = 1; i <= 9; ++i) {
    print('Stdout log$i');
    stderr.writeln('Stderr log$i');
  }
}

Future streamHistoryTest(Isolate isolate, String stream) async {
  final completer = Completer<void>();
  int i = 1;
  await subscribeToStream(isolate.vm, stream, (event) async {
    // Newlines are sent as separate events for some reason. Ignore them.
    if (!event.bytesAsString.startsWith(stream)) {
      return;
    }
    expect(event.bytesAsString, '$stream log$i');
    i++;

    if (i == 10) {
      await cancelStreamSubscription(stream);
      completer.complete();
    } else if (i > 10) {
      fail('Too many log messages');
    }
  });
  await completer.future;
}

var tests = <IsolateTest>[
  isPausedAtStart,
  resumeIsolate,
  (Isolate isolate) async {
    await streamHistoryTest(isolate, 'Stdout');
  },
  (Isolate isolate) async {
    await streamHistoryTest(isolate, 'Stderr');
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
