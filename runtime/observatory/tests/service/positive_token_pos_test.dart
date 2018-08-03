// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override  --verbose_debug --no-sync-async

import 'dart:developer';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
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
  markDartColonLibrariesDebuggable,
  stoppedAtLine(18),
  stepInto,
  (Isolate isolate) async {
    ServiceMap stack = await isolate.getStack();
    expect(stack['frames'].length, greaterThan(3));

    var frame = stack['frames'][0];
    expect(frame.function.name, equals('Completer.sync'));
    expect(await frame.location.getLine(), greaterThan(0));
    expect(await frame.location.getColumn(), greaterThan(0));

    // We used to return a negative token position for this frame.
    // See issue #27128.
    frame = stack['frames'][1];
    expect(frame.function.name, equals('helper'));
    expect(await frame.location.getLine(), equals(12));
    expect(await frame.location.getColumn(), equals(16));

    frame = stack['frames'][2];
    expect(frame.function.name, equals('testMain'));
    expect(await frame.location.getLine(), equals(18));
    expect(await frame.location.getColumn(), equals(3));
  }
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
