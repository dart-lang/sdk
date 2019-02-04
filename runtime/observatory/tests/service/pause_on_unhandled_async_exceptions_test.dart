// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--async_debugger

import 'package:observatory/service_io.dart';
import 'package:observatory/models.dart' as M;
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'service_test_common.dart';

const LINE_A = 34;

class Foo {}

doThrow() {
  throw "TheException"; // Line 13.
  return "end of doThrow";
}

asyncThrower() async {
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
    expect(asyncStack[0].toString(), contains('doThrow'));
    expect(asyncStack[1].toString(), contains('asyncThrower'));
    expect(asyncStack[2].kind, equals(M.FrameKind.asyncSuspensionMarker));
    expect(asyncStack[3].toString(), contains('testeeMain'));
    // We've stopped at LINE_A.
    expect(
        await asyncStack[3].location.toUserString(), contains('.dart:$LINE_A'));
  }
];

main(args) => runIsolateTests(args, tests,
    pause_on_unhandled_exceptions: true, testeeConcurrent: testeeMain);
