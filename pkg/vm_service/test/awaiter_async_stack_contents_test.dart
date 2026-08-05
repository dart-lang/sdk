// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--async-debugger --verbose-debug

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'awaiter_async_stack_contents_lib.dart' as testee_lib;
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

void main([args = const <String>[]]) =>
    IsolateTestHarness('awaiter_async_stack_contents_lib.dart', args)
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_2')
        .stepOver()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_B')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          final Stack stack = await service.getStack(isolateRef.id!);
          // No awaiter frames because we are in a completely synchronous stack.
          expect(stack.asyncCausalFrames, isNull);
        })
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_1')
        .stepOver()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_A')
        .resumeIsolate()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_0')
        .stepOver()
        .hasStoppedAtBreakpoint()
        .stoppedAtLine('LINE_C')
        .addCustomTest((VmService service, IsolateRef isolateRef) async {
          // Verify awaiter stack trace is the current frame + the awaiter.
          final Stack stack = await service.getStack(isolateRef.id!);
          expect(stack.asyncCausalFrames, isNotNull);
          final List<Frame> asyncCausalFrames = stack.asyncCausalFrames!;

          expect(asyncCausalFrames.length, greaterThanOrEqualTo(4));
          expect(asyncCausalFrames[0].function!.name, 'foobar');
          expect(asyncCausalFrames[1].kind, FrameKind.kAsyncSuspensionMarker);
          expect(asyncCausalFrames[2].function!.name, 'helper');
          expect(asyncCausalFrames[3].kind, FrameKind.kAsyncSuspensionMarker);
          // "helper" is not await'ed.
        })
        .run(testeeMain: testee_lib.main, extraArgs: extraDebuggingArgs);
