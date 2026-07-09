// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'step_over_await_lib.dart' as testee_lib;

Future<void> checkAtAsyncSuspension(
  VmService service,
  IsolateRef isolateRef,
) async {
  final isolate = await service.getIsolate(isolateRef.id!);
  expect(isolate.pauseEvent!.atAsyncSuspension, true);
}

void main([args = const <String>[]]) =>
    IsolateTestHarness('step_over_await_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .stepOver()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .stepOver() // At Duration().
        .stepOver() // At Future.delayed().
        .stepOver() // At async.
        // Check that we are at the async statement
        .addCustomTest(checkAtAsyncSuspension)
        .asyncNext()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_C')
        .resumeIsolate()
        .run(testeeMain: testee_lib.main);
