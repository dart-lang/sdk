// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override  --verbose_debug --async_debugger

import 'dart:developer';
import 'dart:io';

import 'service_test_common.dart';
import 'test_helper.dart';

helper() async {
  print('helper'); // LINE_A.
  print('foobar'); // LINE_B.
}

testMain() {
  debugger();
  print('mmmmm'); // LINE_C.
  helper(); // LINE_D.
  print('z');
}

final ScriptLineParser lineParser = new ScriptLineParser(Platform.script);

var tests = [
  hasStoppedAtBreakpoint,
  stoppedAtLine(lineParser.lineFor('LINE_C')),
  stepOver, // print.
  hasStoppedAtBreakpoint,
  stoppedAtLine(lineParser.lineFor('LINE_D')),
  stepInto,
  hasStoppedAtBreakpoint,
  stoppedAtLine(lineParser.lineFor('LINE_A')),
  stepOver, // print.
  hasStoppedAtBreakpoint,
  stoppedAtLine(lineParser.lineFor('LINE_B')),
  resumeIsolate
];

main(args) =>
    runIsolateTestsSynchronous(args, tests, testeeConcurrent: testMain);
