// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that debugger can stop on an unhandled exception thrown from async
// function. Regression test for https://dartbug.com/38697.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'pause_on_unhandled_async_exceptions3_lib.dart' as testee_lib;

void main([args = const <String>[]]) => IsolateTestHarness(
        'pause_on_unhandled_async_exceptions3_lib.dart', args)
    .hasStoppedWithUnhandledException()
    .stoppedAtLine('LINE_A')
    .addCustomTestWithParser(
      (
        VmService service,
        IsolateRef isolateRef,
        TestScriptParser parser,
      ) async {
        final isolateId = isolateRef.id!;
        final stack = await service.getStack(isolateId);
        expect(stack.frames, isNotEmpty);
        expect(stack.frames![0].function!.name, 'throwException');
        expect(stack.frames![0].location!.line, parser.lineForTag('LINE_A'));
      },
    )
    .resumeIsolate()
    .hasStoppedWithUnhandledException()
    .addCustomTestWithParser(
      (
        VmService service,
        IsolateRef isolateRef,
        TestScriptParser parser,
      ) async {
        final isolateId = isolateRef.id!;
        final stack = await service.getStack(isolateId);
        expect(stack.frames, isNotEmpty);
        // await in testeeMain
        expect(stack.frames![0].location!.line, parser.lineForTag('LINE_B'));
      },
    )
    .resumeIsolate()
    .hasStoppedWithUnhandledException()
    .stoppedAtLine('LINE_A')
    .resumeIsolate()
    .hasStoppedWithUnhandledException()
    .addCustomTestWithParser(
      (
        VmService service,
        IsolateRef isolateRef,
        TestScriptParser parser,
      ) async {
        final isolateId = isolateRef.id!;
        final stack = await service.getStack(isolateId);
        expect(stack.frames, isNotEmpty);
        expect(stack.frames![0].location!.line, parser.lineForTag('LINE_C'));
      },
    )
    .run(testeeMain: testee_lib.main, pauseOnUnhandledExceptions: true);
