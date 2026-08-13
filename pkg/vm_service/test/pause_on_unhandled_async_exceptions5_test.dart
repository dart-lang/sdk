// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that debugger correctly detects `catchError` even when it occurs
// without a value listener, as in `Future(...).catchError(...)`.
//
// Regression test for https://github.com/flutter/flutter/issues/141882.

import 'common/service_test_common.dart';
import 'common/test_helper.dart';
import 'pause_on_unhandled_async_exceptions5_lib.dart' as testee_lib;

void main([List<String> args = const []]) {
  IsolateTestHarness(
    'pause_on_unhandled_async_exceptions5_lib.dart',
    args,
  )
      .hasStoppedWithUnhandledException()
      .stoppedAtLine('LINE_A')
      .addCustomTestWithParser((service, isolate, parser) async {
    final stack = await service.getStack(isolate.id!);
    final frames = stack.asyncCausalFrames!;
    await expectFrame(
      service,
      isolate,
      frames[0],
      functionName: 'doThrowAsync',
      line: parser.lineForTag('LINE_A'),
    );
    await expectFrame(
      service,
      isolate,
      frames[1],
      kind: 'AsyncSuspensionMarker',
    );
    await expectFrame(
      service,
      isolate,
      frames[2],
      kind: 'AsyncCausal',
      functionName: 'testeeMain',
      line: parser.lineForTag('LINE_C'),
    );
  }).run(
    testeeMain: testee_lib.main,
    pauseOnUnhandledExceptions: true,
    extraArgs: extraDebuggingArgs,
  );
}
