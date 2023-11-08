// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

void testMain() {
  print('Hello');
}

final tests = <IsolateTest>[
  hasPausedAtStart,
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Grab the timestamp.
    final pausetime1 = isolate.pauseEvent!.timestamp;
    expect(pausetime1, isNotNull);

    // Reload the isolate.
    final reloaded = await service.getIsolate(isolateId);
    // Verify that it is the same.
    expect(pausetime1, reloaded.pauseEvent!.timestamp);
  },
  resumeIsolate,
  hasStoppedAtExit,
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Grab the timestamp.
    final pausetime1 = isolate.pauseEvent!.timestamp;
    expect(pausetime1, isNotNull);

    // Reload the isolate.
    final reloaded = await service.getIsolate(isolateId);
    // Verify that it is the same.
    expect(pausetime1, reloaded.pauseEvent!.timestamp);
  },
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'pause_on_start_and_exit_test.dart',
      testeeConcurrent: testMain,
      pause_on_start: true,
      pause_on_exit: true,
      verbose_vm: true,
      extraArgs: ['--trace-service', '--trace-service-verbose'],
    );
