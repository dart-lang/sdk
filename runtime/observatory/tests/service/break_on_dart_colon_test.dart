// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'dart:developer';

import 'package:observatory/service_io.dart';

import 'service_test_common.dart';
import 'test_helper.dart';

// Line in core/print.dart
const int LINE_A = 19;

testMain() {
  debugger();
  print('1');
  print('2');
  print('3');
  print('Done');
}

IsolateTest expectHitBreakpoint(String uri, int line) {
  return (Isolate isolate) async {
    final bpt = await isolate.addBreakpointByScriptUri(uri, line);
    await resumeIsolate(isolate);
    await hasStoppedAtBreakpoint(isolate);
    await stoppedAtLine(line)(isolate);
    await isolate.removeBreakpoint(bpt);
  };
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,

  // Dart libraries are not debuggable by default
  markDartColonLibrariesDebuggable,

  expectHitBreakpoint('org-dartlang-sdk:///sdk/lib/core/print.dart', LINE_A),
  expectHitBreakpoint('dart:core/print.dart', LINE_A),
  expectHitBreakpoint('/core/print.dart', LINE_A),

  resumeIsolate,
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
