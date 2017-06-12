// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override  --verbose_debug

import 'dart:developer';
import 'dart:io';

import 'service_test_common.dart';
import 'test_helper.dart';

foo() async {}

doAsync(stop) async {
  if (stop) debugger();
  await foo(); // LINE_A.
  await foo(); // LINE_B.
  await foo(); // LINE_C.
  return null;
}

testMain() {
  // With two runs of doAsync floating around, async step should only cause
  // us to stop in the run we started in.
  doAsync(false);
  doAsync(true);
}

final ScriptLineParser lineParser = new ScriptLineParser(Platform.script);

var tests = [
  hasStoppedAtBreakpoint,
  stoppedAtLine(lineParser.lineFor('LINE_A')),
  stepOver, // foo()
  asyncNext,
  hasStoppedAtBreakpoint,
  stoppedAtLine(lineParser.lineFor('LINE_B')),
  stepOver, // foo()
  asyncNext,
  hasStoppedAtBreakpoint,
  stoppedAtLine(lineParser.lineFor('LINE_C')),
  resumeIsolate,
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
