// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate' as isolate;

import 'package:vm_service/vm_service.dart';
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

void child(message) {
  print('Child got initial message');
  message.send(null);
}

void testMain() {
  final port = isolate.RawReceivePort();
  port.handler = (message) {
    print('Parent got response');
    port.close();
  };

  isolate.Isolate.spawn(child, port.sendPort);
}

final tests = <IsolateTest>[
  hasPausedAtStart,
  (VmService service, IsolateRef isolateRef) async {
    // Disabling these flags will result in any new isolates spawned not
    // pausing on start or exit. However, existing isolates will maintain their
    // existing flags and the main isolate should pause at exit.
    await service.setFlag('pause_isolates_on_start', 'false');
    await service.setFlag('pause_isolates_on_exit', 'false');
  },
  resumeIsolate,
  // When the main isolate is resumed, we expect the child isolate to spawn and
  // immediately exit after sending a message to the main isolate. The main
  // isolate will only exit when `port` is closed after the message sent by the
  // child is received.
  hasStoppedAtExit,
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'pause_on_start_and_exit_with_child_test.dart',
      testeeConcurrent: testMain,
      pauseOnStart: true,
      pauseOnExit: true,
      extraArgs: [
        '--trace-service',
        '--trace-service-verbose',
      ],
    );
