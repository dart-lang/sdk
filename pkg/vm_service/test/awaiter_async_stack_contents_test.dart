// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--async-debugger --verbose-debug

import 'dart:developer';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const LINE_C = 26;
const LINE_A = 32;
const LINE_B = 38;
const LINE_D = 33;

const LINE_0 = 25;
const LINE_1 = 31;
const LINE_2 = 37;

foobar() async {
  await null;
  debugger(); // LINE_0.
  print('foobar'); // LINE_C.
}

helper() async {
  await null;
  debugger(); // LINE_1.
  print('helper'); // LINE_A.
  await foobar(); // LINE_D
}

testMain() {
  debugger(); // LINE_2.
  helper(); // LINE_B.
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_2),
  stepOver,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  (VmService service, IsolateRef isolateRef) async {
    Stack stack = await service.getStack(isolateRef.id!);
    // No awaiter frames because we are in a completely synchronous stack.
    expect(stack.asyncCausalFrames, isNull);
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_1),
  stepOver,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_0),
  stepOver,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  (VmService service, IsolateRef isolateRef) async {
    // Verify awaiter stack trace is the current frame + the awaiter.
    Stack stack = await service.getStack(isolateRef.id!);
    expect(stack.asyncCausalFrames, isNotNull);
    List<Frame> asyncCausalFrames = stack.asyncCausalFrames!;

    expect(asyncCausalFrames.length, greaterThanOrEqualTo(4));
    expect(asyncCausalFrames[0].function!.name, 'foobar');
    expect(asyncCausalFrames[1].kind, FrameKind.kAsyncSuspensionMarker);
    expect(asyncCausalFrames[2].function!.name, 'helper');
    expect(asyncCausalFrames[3].kind, FrameKind.kAsyncSuspensionMarker);
    // "helper" is not await'ed.
  },
];

main(args) => runIsolateTestsSynchronous(
      args,
      tests,
      'awaiter_async_stack_contents_test.dart',
      testeeConcurrent: testMain,
      extraArgs: extraDebuggingArgs,
    );
