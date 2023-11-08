// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';
import 'common/service_test_common.dart';

const LINE_A = 15;

void testMain() {
  debugger(); // LINE_A
  print('1');
  while (true) {}
}

final tests = <IsolateTest>[
  // Stopped at 'debugger' statement.
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  // Kill the app.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    await service.kill(isolateId);
  }
];

void main([args = const <String>[]]) async => runIsolateTests(
      args,
      tests,
      'kill_paused_test.dart',
      testeeConcurrent: testMain,
      // The target will exit with a 255 exit code. Without this flag, it's
      // possible for this test to fail flakily in the case where the process
      // exits before the test cleanly tears down.
      allowForNonZeroExitCode: true,
    );
