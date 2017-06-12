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
  throw 'a'; // LINE_B.
  return null;
}

testMain() async {
  debugger();
  print('mmmmm'); // LINE_C.
  try {
    await helper(); // LINE_D.
  } catch (e) {
    // arrive here on error.
    print('error: $e'); // LINE_E.
  } finally {
    // arrive here in both cases.
    print('foo'); // LINE_F.
  }
  print('z'); // LINE_G.
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
  stoppedAtLine(lineParser.lineFor('LINE_B')), // throw 'a'.
  stepInto, // exit helper via a throw.
  hasStoppedAtBreakpoint,
  stepInto, // exit helper via a throw.
  hasStoppedAtBreakpoint,
  stepInto, // step once from entry to main.
  hasStoppedAtBreakpoint,
  stoppedAtLine(lineParser.lineFor('LINE_E')), // print(error)
  stepOver,
  hasStoppedAtBreakpoint,
  stepOver,
  hasStoppedAtBreakpoint,
  stoppedAtLine(lineParser.lineFor('LINE_F')), // print(foo)
  stepOver,
  hasStoppedAtBreakpoint,
  stoppedAtLine(lineParser.lineFor('LINE_G')), // print(z)
  resumeIsolate
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
