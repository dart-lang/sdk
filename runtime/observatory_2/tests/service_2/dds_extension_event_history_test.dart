// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'client_resume_approvals_common.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

Future testMain() async {
  // Post a total of 9 events
  for (int i = 1; i <= 9; ++i) {
    postEvent('Test', {
      'id': i,
    });
  }
}

var tests = <IsolateTest>[
  isPausedAtStart,
  resumeIsolate,
  (Isolate isolate) async {
    final completer = Completer<void>();
    int i = 1;
    await subscribeToStream(isolate.vm, 'Extension', (event) async {
      expect(event.extensionKind, 'Test');
      expect(event.extensionData['id'], i);
      i++;

      if (i == 10) {
        await cancelStreamSubscription('Extension');
        completer.complete();
      } else if (i > 10) {
        fail('Too many log messages');
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
