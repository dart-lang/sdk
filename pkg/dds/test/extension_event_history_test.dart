// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

Future testMain() async {
  // Post a total of 9 events
  for (int i = 1; i <= 9; ++i) {
    postEvent('Test', {
      'id': i,
    });
  }
}

final tests = <IsolateTest>[
  hasPausedAtStart,
  resumeIsolate,
  (VmService service, IsolateRef isolateRef) async {
    final completer = Completer<void>();
    int i = 1;
    service.onExtensionEvent.listen((event) async {
      expect(event.extensionKind, 'Test');
      expect(event.extensionData!.data['id'], i);
      i++;

      if (i == 10) {
        await service.streamCancel(EventStreams.kExtension);
        completer.complete();
      } else if (i > 10) {
        fail('Too many "Test" extension events');
      }
    });
    await service.streamListen(EventStreams.kExtension);
    await completer.future;
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'extension_event_history_test.dart',
      testeeConcurrent: testMain,
      pauseOnStart: true,
      pauseOnExit: true,
    );
