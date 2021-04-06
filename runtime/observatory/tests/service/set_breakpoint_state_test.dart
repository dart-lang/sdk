// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';

import 'service_test_common.dart';
import 'test_helper.dart';

const int LINE_A = 17;
const int LINE_B = LINE_A + 1;

testMain() {
  while (true) {
    print('a'); // LINE_A
    print('b'); // LINE_B
  }
}

late Breakpoint bpt;

var tests = <IsolateTest>[
  hasPausedAtStart,
  (Isolate isolate) async {
    bpt = await isolate.addBreakpointByScriptUri(
      'set_breakpoint_state_test.dart',
      LINE_A,
    );
    expect(bpt.enabled, true);
  },
  setBreakpointAtLine(LINE_B),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  (Isolate isolate) async {
    await bpt.setState(
      false,
    );
    expect(bpt.enabled, false);
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  (Isolate isolate) async {
    await bpt.setState(
      true,
    );
    expect(bpt.enabled, true);
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
];

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      pause_on_start: true,
      testeeConcurrent: testMain,
    );
