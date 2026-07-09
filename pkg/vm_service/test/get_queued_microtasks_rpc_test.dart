// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'get_queued_microtasks_rpc_lib.dart' as testee_lib;

const String shortFile = 'get_queued_microtasks_rpc_lib.dart';
const int numberOfMicrotasksToSchedule = 5;

void main([args = const <String>[]]) =>
    IsolateTestHarness('get_queued_microtasks_rpc_lib.dart', args)
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
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
    }).run(
      testeeMain: testee_lib.main,
      extraArgs: ['--profile-microtasks'],
    );
