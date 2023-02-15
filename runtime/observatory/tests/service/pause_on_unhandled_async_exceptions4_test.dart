// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that execution can be stopped on an unhandled exception
// in async method which is not awaited.
// Regression test for https://github.com/dart-lang/sdk/issues/51175.

import 'package:observatory/service_io.dart';
import 'package:observatory/models.dart' as M;
import 'package:test/test.dart';
import 'test_helper.dart';
import 'service_test_common.dart';

doThrow() async {
  await null; // force async gap
  throw 'TheException';
}

testeeMain() async {
  doThrow();
}

var tests = <IsolateTest>[
  hasStoppedWithUnhandledException,
  (Isolate isolate) async {
    print("We stopped!");
    var stack = await isolate.getStack();
    expect(stack['asyncCausalFrames'], isNotNull);
    var asyncStack = stack['asyncCausalFrames'];
    expect(asyncStack.length, greaterThanOrEqualTo(2));
    expect(asyncStack[0].toString(), contains('doThrow'));
    expect(asyncStack[1].kind, equals(M.FrameKind.asyncSuspensionMarker));
  }
];

main(args) => runIsolateTests(args, tests,
    pause_on_unhandled_exceptions: true,
    testeeConcurrent: testeeMain,
    extraArgs: extraDebuggingArgs);
