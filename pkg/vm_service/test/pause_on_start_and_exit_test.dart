// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'pause_on_start_and_exit_lib.dart' as testee_lib;

Future<void> verifyPauseTimestamp(
  VmService service,
  IsolateRef isolateRef,
) async {
  final isolateId = isolateRef.id!;
  final isolate = await service.getIsolate(isolateId);
  // Grab the timestamp.
  final pausetime1 = isolate.pauseEvent!.timestamp;
  expect(pausetime1, isNotNull);

  // Reload the isolate.
  final reloaded = await service.getIsolate(isolateId);
  // Verify that it is the same.
  expect(pausetime1, reloaded.pauseEvent!.timestamp);
}

void main([args = const <String>[]]) =>
    IsolateTestHarness('pause_on_start_and_exit_lib.dart', args)
        .hasPausedAtStart()
        .addCustomTest(verifyPauseTimestamp)
        .resumeIsolate()
        .hasStoppedAtExit()
        .addCustomTest(verifyPauseTimestamp)
        .run(
      testeeMain: testee_lib.main,
      pauseOnStart: true,
      pauseOnExit: true,
      extraArgs: ['--trace-service', '--trace-service-verbose'],
    );
