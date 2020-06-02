// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';
import 'dart:developer';

testParameters(int jjjj, int oooo, [int? hhhh, int? nnnn]) {
  debugger();
}

testMain() {
  int? xxx, yyyy, zzzzz;
  for (int i = 0; i < 1; i++) {
    var foo = () {};
    debugger();
  }
  var bar = () {
    print(xxx);
    print(yyyy);
    debugger();
  };
  bar();
  testParameters(0, 0);
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedInFunction('testMain'),
  (Isolate isolate) async {
    var stack = await isolate.getStack();
    expect(stack.type, equals('Stack'));
    expect(stack['frames'].length, greaterThanOrEqualTo(1));
    // Grab the top frame.
    Frame frame = stack['frames'][0];
    // Grab the script.
    Script script = frame.location!.script;
    await script.load();

    // Ensure that the token at each declaration position is the name of the
    // variable.
    for (var variable in frame.variables) {
      final int declarationTokenPos = variable['declarationTokenPos'];
      final String name = variable['name'];
      final String? token = script.getToken(declarationTokenPos);
      // When running from an appjit snapshot, sources aren't available so the returned token will
      // be null.
      if (token != null) {
        expect(name, token);
      }
    }
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  // We have stopped in the anonymous closure assigned to bar. Verify that
  // variables captured in the context have valid declaration positions.
  (Isolate isolate) async {
    var stack = await isolate.getStack();
    expect(stack.type, equals('Stack'));
    expect(stack['frames'].length, greaterThanOrEqualTo(1));
    // Grab the top frame.
    Frame frame = stack['frames'][0];
    // Grab the script.
    Script script = frame.location!.script;
    await script.load();
    print(frame);
    expect(frame.variables.length, greaterThanOrEqualTo(1));
    for (var variable in frame.variables) {
      final int declarationTokenPos = variable['declarationTokenPos'];
      final String name = variable['name'];
      final String? token = script.getToken(declarationTokenPos);
      // When running from an appjit snapshot, sources aren't available so the returned token will
      // be null.
      if (token != null) {
        expect(name, token);
      }
    }
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedInFunction('testParameters'),
  (Isolate isolate) async {
    var stack = await isolate.getStack();
    expect(stack.type, equals('Stack'));
    expect(stack['frames'].length, greaterThanOrEqualTo(1));
    // Grab the top frame.
    Frame frame = stack['frames'][0];
    // Grab the script.
    Script script = frame.location!.script;
    await script.load();

    // Ensure that the token at each declaration position is the name of the
    // variable.
    expect(frame.variables.length, greaterThanOrEqualTo(1));
    for (var variable in frame.variables) {
      final int declarationTokenPos = variable['declarationTokenPos'];
      final String name = variable['name'];
      final String? token = script.getToken(declarationTokenPos);
      // When running from an appjit snapshot, sources aren't available so the returned token will
      // be null.
      if (token != null) {
        expect(name, token);
      }
    }
  }
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
