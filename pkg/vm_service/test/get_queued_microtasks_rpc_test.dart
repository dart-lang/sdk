// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const String shortFile = 'get_queued_microtasks_rpc_test.dart';
const int numberOfMicrotasksToSchedule = 5;

Future<void> testeeMain() async {
  for (int i = 0; i < numberOfMicrotasksToSchedule; i++) {
    scheduleMicrotask(() {});
    debugger();
    // Give the microtask that we just scheduled an opportunity to run.
    await Future.delayed(const Duration(milliseconds: 1));
  }
}

final tests = <IsolateTest>[
  (VmService service, IsolateRef isolateRef) async {
    for (int i = 0; i < numberOfMicrotasksToSchedule; i++) {
      await hasStoppedAtBreakpoint(service, isolateRef);
      final result = await service.getQueuedMicrotasks(
        isolateRef.id!,
      );

      expect(result.timestamp, isPositive);
      expect(result.microtasks!.length, 1);
      expect(result.microtasks!.first.id, i);
      expect(result.microtasks!.first.stackTrace, contains(shortFile));
      await service.resume(isolateRef.id!);
    }
  },
];

Future<void> main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      shortFile,
      testeeConcurrent: testeeMain,
      extraArgs: ['--profile-microtasks'],
    );
