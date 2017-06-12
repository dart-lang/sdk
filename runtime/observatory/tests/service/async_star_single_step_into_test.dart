// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override  --verbose_debug --async_debugger

import 'dart:developer';
import 'dart:io';

import 'service_test_common.dart';
import 'test_helper.dart';

foobar() async* {
  yield 1; // LINE_A.
  yield 2; // LINE_B.
}

helper() async {
  print('helper'); // LINE_C.
  await for (var i in foobar()) {
    debugger();
    print('loop'); // LINE_D.
  }
}

testMain() {
  debugger();
  print('mmmmm'); // LINE_E.
  helper(); // LINE_F.
  print('z');
}

final ScriptLineParser lineParser = new ScriptLineParser(Platform.script);

var tests = [
  hasStoppedAtBreakpoint,
  stoppedAtLine(lineParser.lineFor('LINE_E')),
  stepOver, // print.
  hasStoppedAtBreakpoint,
  stoppedAtLine(lineParser.lineFor('LINE_F')),
  stepInto,
  hasStoppedAtBreakpoint,
  stoppedAtLine(lineParser.lineFor('LINE_C')),
  stepOver, // print.
  hasStoppedAtBreakpoint,
  stepInto,
  hasStoppedAtBreakpoint,
  stoppedAtLine(lineParser.lineFor('LINE_A')),
  // Resume here to exit the generator function.
  // TODO(johnmccutchan): Implement support for step-out of async functions.
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(lineParser.lineFor('LINE_D')),
  stepOver, // print.
  hasStoppedAtBreakpoint,
  stepInto,
  hasStoppedAtBreakpoint,
  stoppedAtLine(lineParser.lineFor('LINE_B')),
  resumeIsolate,
];

main(args) =>
    runIsolateTestsSynchronous(args, tests, testeeConcurrent: testMain);
