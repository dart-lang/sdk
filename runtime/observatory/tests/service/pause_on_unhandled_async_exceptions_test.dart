// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--async_debugger --no-causal-async-stacks --lazy-async-stacks
// VMOptions=--async_debugger --causal-async-stacks --no-lazy-async-stacks

import 'package:observatory/service_io.dart';
import 'package:observatory/models.dart' as M;
import 'package:test/test.dart';
import 'test_helper.dart';
import 'service_test_common.dart';

const LINE_A = 36;

class Foo {}

doThrow() {
  throw "TheException"; // Line 13.
  return "end of doThrow";
}

asyncThrower() async {
  await 0; // force async gap
  doThrow();
}

testeeMain() async {
  try {
    // caught.
    try {
      await asyncThrower();
    } catch (e) {}

    // uncaught.
    try {
      await asyncThrower(); // LINE_A.
    } on double catch (e) {}
  } on Foo catch (e) {}
}

var tests = <IsolateTest>[
  hasStoppedWithUnhandledException,
  (Isolate isolate) async {
    print("We stopped!");
    var stack = await isolate.getStack();
    expect(stack['asyncCausalFrames'], isNotNull);
    var asyncStack = stack['asyncCausalFrames'];
    if (useCausalAsyncStacks) {
      expect(asyncStack.length, greaterThanOrEqualTo(4));
      expect(asyncStack[0].toString(), contains('doThrow'));
      expect(asyncStack[1].toString(), contains('asyncThrower'));
      expect(asyncStack[2].kind, equals(M.FrameKind.asyncSuspensionMarker));
      expect(asyncStack[3].toString(), contains('testeeMain'));
      // We've stopped at LINE_A.
      expect(await asyncStack[3].location.toUserString(),
          contains('.dart:$LINE_A'));
    } else {
      expect(asyncStack.length, greaterThanOrEqualTo(2));
      expect(asyncStack[0].toString(), contains('doThrow'));
      expect(asyncStack[1].toString(), contains('asyncThrower'));
      // There was no await'er for "doThrow()".
    }
  }
];

main(args) => runIsolateTests(args, tests,
    pause_on_unhandled_exceptions: true,
    testeeConcurrent: testeeMain,
    extraArgs: extraDebuggingArgs);
