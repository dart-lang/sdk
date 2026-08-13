// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';
import 'pause_on_unhandled_async_exceptions_zones_lib.dart' as testee_lib;

void main([args = const <String>[]]) => IsolateTestHarness(
      'pause_on_unhandled_async_exceptions_zones_lib.dart',
      args,
    ).hasStoppedWithUnhandledException().addCustomTestWithParser(
      (
        VmService service,
        IsolateRef isolateRef,
        TestScriptParser parser,
      ) async {
        final isolateId = isolateRef.id!;
        final stack = await service.getStack(isolateId);
        expect(stack.asyncCausalFrames, isNotNull);
        final asyncStack = stack.asyncCausalFrames!;
        expect(asyncStack.length, greaterThanOrEqualTo(4));
        expect(asyncStack[0].function!.name, 'doThrow');
        expect(asyncStack[1].function!.name, 'asyncThrower');
        expect(asyncStack[2].kind, FrameKind.kAsyncSuspensionMarker);
        expect(asyncStack[3].kind, FrameKind.kAsyncCausal);
        expect(asyncStack[3].function!.name, 'testeeMain');
        expect(asyncStack[3].location!.line, parser.lineForTag('LINE_A'));
      },
    ).run(
      testeeMain: testee_lib.main,
      pauseOnUnhandledExceptions: true,
      extraArgs: extraDebuggingArgs,
    );
