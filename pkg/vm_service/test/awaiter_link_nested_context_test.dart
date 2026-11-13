// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that the async awaiter stack follows a callback wrapper whose
// awaiter link variable is in an enclosing closure's context.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'awaiter_link_nested_context_lib.dart' as testee_lib;
import 'common/service_test_common.dart';

void main([args = const <String>[]]) => IsolateTestHarness(
      'awaiter_link_nested_context_lib.dart',
      args,
    ).hasStoppedWithUnhandledException().addCustomTestWithParser(
      (
        VmService service,
        IsolateRef isolateRef,
        TestScriptParser parser,
      ) async {
        final stack = await service.getStack(isolateRef.id!);
        final asyncStack = stack.asyncCausalFrames!;
        expect(asyncStack.length, greaterThanOrEqualTo(4));
        expect(asyncStack[0].function!.name, 'doThrow');
        expect(asyncStack[1].function!.name, 'asyncThrower');
        expect(asyncStack[2].kind, FrameKind.kAsyncSuspensionMarker);
        expect(asyncStack[3].kind, FrameKind.kAsyncCausal);
        expect(asyncStack[3].location!.line, parser.lineForTag('LINE_A'));
      },
    ).run(
      testeeMain: testee_lib.main,
      pauseOnUnhandledExceptions: true,
    );
