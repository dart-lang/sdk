// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--verbose_debug

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'causal_async_star_stack_contents_lib.dart' as testee_lib;
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

Future<void> testSynchronousStack(
  VmService service,
  IsolateRef isolateRef,
) async {
  final Stack stack = await service.getStack(isolateRef.id!);
  // No causal frames because we are in a completely synchronous stack.
  expect(stack.asyncCausalFrames, isNotNull);
  final asyncStack = stack.asyncCausalFrames!;
  expect(asyncStack.length, greaterThanOrEqualTo(1));
  expect(asyncStack[0].function!.name, contains('helper'));
  // helper isn't awaited.
}

Future<void> testAsyncStack1(
  VmService service,
  IsolateRef isolateRef,
) async {
  final Stack stack = await service.getStack(isolateRef.id!);
  // Has causal frames (we are inside an async function)
  expect(stack.asyncCausalFrames, isNotNull);
  final asyncStack = stack.asyncCausalFrames!;
  expect(asyncStack.length, greaterThanOrEqualTo(3));
  expect(asyncStack[0].function!.name, contains('foobar'));
  expect(asyncStack[1].kind, equals(FrameKind.kAsyncSuspensionMarker));
  expect(asyncStack[2].function!.name, contains('helper'));
  expect(asyncStack[3].kind, equals(FrameKind.kAsyncSuspensionMarker));
}

Future<void> testAsyncStack2(
  VmService service,
  IsolateRef isolateRef,
  TestScriptParser parser,
) async {
  final Stack stack = await service.getStack(isolateRef.id!);
  // Has causal frames (we are inside a function called by an async function)
  expect(stack.asyncCausalFrames, isNotNull);
  final asyncStack = stack.asyncCausalFrames!;
  expect(asyncStack.length, greaterThanOrEqualTo(4));
  final script = await service.getObject(
    isolateRef.id!,
    asyncStack[0].location!.script!.id!,
  ) as Script;
  expect(asyncStack[0].function!.name, contains('foobar'));
  expect(
    script.getLineNumberFromTokenPos(asyncStack[0].location!.tokenPos!),
    parser.lineForTag('LINE_C'),
  );
  expect(asyncStack[1].kind, equals(FrameKind.kAsyncSuspensionMarker));
  expect(asyncStack[2].function!.name, contains('helper'));
  expect(
    script.getLineNumberFromTokenPos(asyncStack[2].location!.tokenPos!),
    parser.lineForTag('LINE_D'),
  );
  expect(asyncStack[3].kind, equals(FrameKind.kAsyncSuspensionMarker));
}

void main([args = const <String>[]]) =>
    IsolateTestHarness('causal_async_star_stack_contents_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_2')
        .stepOver()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .addCustomTest(testSynchronousStack)
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_0')
        .stepOver()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .addCustomTest(testAsyncStack1)
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_1')
        .stepOver()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_C')
        .addCustomTestWithParser(testAsyncStack2)
        .run(testeeMain: testee_lib.main, extraArgs: extraDebuggingArgs);
