// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'dart:developer';
import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

helper() async {
  // Line 12, Col 16 is the open brace.
}

testMain() {
  debugger();
  helper(); // Line 18, Col 3 is the position of the function call.
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(18),
  stepInto,
  (Isolate isolate) async {
    ServiceMap stack = await isolate.getStack();
    expect(stack['frames'].length, greaterThan(2));

    // We used to return a negative token position for this frame.
    // See issue #27128.
    var frame = stack['frames'][0];
    expect(frame.function.qualifiedName, equals('helper.async_op'));
    expect(await frame.location.getLine(), equals(14));
    expect(await frame.location.getColumn(), equals(1));

    frame = stack['frames'][1];
    expect(frame.function.name, equals('testMain'));
    expect(await frame.location.getLine(), equals(18));
    expect(await frame.location.getColumn(), equals(3));
  }
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
