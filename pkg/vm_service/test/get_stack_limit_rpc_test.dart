// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

Future<void> bar(int depth) async {
  if (depth == 21) {
    debugger();
    return;
  }
  await foo(depth + 1);
}

Future<void> foo(int depth) async {
  if (depth == 10) {
    // Yield once to force the rest to run async.
    await 0;
  }
  await bar(depth + 1);
}

Future<void> testMain() async {
  await foo(0);
}

void verifyStack(List<Frame> frames, List<String> expectedNames) {
  for (int i = 0; i < frames.length && i < expectedNames.length; ++i) {
    expect(frames[i].function!.name, expectedNames[i]);
  }
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  // Get stack
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    var stack = await service.getStack(isolateId);

    // Sanity check.
    var frames = stack.frames!;
    var asyncFrames = stack.asyncCausalFrames!;
    expect(frames.length, greaterThanOrEqualTo(12));
    expect(asyncFrames.length, greaterThan(frames.length));
    expect(stack.truncated, false);
    verifyStack(frames, [
      'bar',
      'foo',
      'bar',
      'foo',
      'bar',
      'foo',
      'bar',
      'foo',
      'bar',
      'foo',
      'bar',
      'foo'
    ]);

    final fullStackLength = frames.length;

    // Try a limit > actual stack depth and expect to get the full stack with
    // truncated async stacks.
    stack = await service.getStack(isolateId, limit: fullStackLength + 1);
    frames = stack.frames!;
    asyncFrames = stack.asyncCausalFrames!;

    expect(frames.length, fullStackLength);
    expect(asyncFrames.length, fullStackLength + 1);
    expect(stack.truncated, true);
    verifyStack(frames, [
      'bar',
      'foo',
      'bar',
      'foo',
      'bar',
      'foo',
      'bar',
      'foo',
      'bar',
      'foo',
      'bar',
      'foo'
    ]);

    // Try a limit < actual stack depth and expect to get a stack of depth
    // 'limit'.
    stack = await service.getStack(isolateId, limit: 10);
    frames = stack.frames!;
    asyncFrames = stack.asyncCausalFrames!;

    expect(frames.length, 10);
    expect(asyncFrames.length, 10);
    expect(stack.truncated, true);
    verifyStack(frames, [
      'bar',
      'foo',
      'bar',
      'foo',
      'bar',
      'foo',
      'bar',
      'foo',
      'bar',
      'foo',
    ]);
  },
  // Invalid limit
  (VmService service, IsolateRef isolateRef) async {
    bool caughtException = false;
    try {
      await service.getStack(isolateRef.id!, limit: -1);
      fail('Invalid parameter of -1 successful');
    } on RPCError {
      // Expected.
      caughtException = true;
    }
    expect(caughtException, true);
  }
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'get_stack_limit_rpc_test.dart',
      testeeConcurrent: testMain,
    );
