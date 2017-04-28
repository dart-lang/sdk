// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override --async_debugger
// VMOptions=--optimization-counter-threshold=5 --error_on_bad_type --error_on_bad_override --async_debugger

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
  // Trigger optimization via OSR.
  var s = 0;
  for (var i = 0; i < 100; i++) {
    s += i;
  }
  print(s);
  // No try ... catch.
  await asyncThrower(); // LINE_A
}

var tests = [
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
