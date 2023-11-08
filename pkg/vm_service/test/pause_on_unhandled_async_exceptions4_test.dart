// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that execution can be stopped on an unhandled exception
// in async method which is not awaited.
// Regression test for https://github.com/dart-lang/sdk/issues/51175.

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/test_helper.dart';
import 'common/service_test_common.dart';

Future<Never> doThrow() async {
  await null; // force async gap
  throw 'TheException';
}

Future<void> testeeMain() async {
  doThrow();
}

final tests = <IsolateTest>[
  hasStoppedWithUnhandledException,
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final stack = await service.getStack(isolateId);
    expect(stack.asyncCausalFrames, isNotNull);
    final asyncStack = stack.asyncCausalFrames!;
    expect(asyncStack.length, greaterThanOrEqualTo(2));
    expect(asyncStack[0].function!.name, 'doThrow');
    expect(asyncStack[1].kind, FrameKind.kAsyncSuspensionMarker);
  }
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'pause_on_unhandled_async_exceptions4_test.dart',
      pause_on_unhandled_exceptions: true,
      testeeConcurrent: testeeMain,
      extraArgs: extraDebuggingArgs,
    );
