// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:test/test.dart';

import 'package:observatory/service_io.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

int LINE_A = 35;
int LINE_B = 40;
int LINE_C = 43;
int LINE_D = 47;

int LINE_0 = 33;

int global = 0;

@pragma('vm:never-inline')
b3(int x) {
  int sum = 0;
  try {
    for (int i = 0; i < x; i++) {
      sum += x;
    }
  } catch (e) {
    print("caught $e");
  }
  if (global >= 100) {
    debugger(); // LINE_0.
  }
  global = global + 1; // LINE_A.
  return sum;
}

@pragma('vm:prefer-inline')
b2(x) => b3(x); // LINE_B.

@pragma('vm:prefer-inline')
b1(x) => b2(x); // LINE_C.

test() {
  while (true) {
    b1(10000); // LINE_D.
  }
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_0),
  stepOver,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  (Isolate isolate) async {
    // We are not able to rewind frame 0.
    bool caughtException = false;
    try {
      await isolate.rewind(0);
      expect(false, isTrue, reason: 'Unreachable');
    } on ServerRpcException catch (e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kCannotResume));
      expect(e.message, 'Frame must be in bounds [1..8]: saw 0');
    }
    expect(caughtException, isTrue);
  },
  (Isolate isolate) async {
    // We are not able to rewind frame 13.
    bool caughtException = false;
    try {
      await isolate.rewind(13);
      expect(false, isTrue, reason: 'Unreachable');
    } on ServerRpcException catch (e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kCannotResume));
      expect(e.message, 'Frame must be in bounds [1..8]: saw 13');
    }
    expect(caughtException, isTrue);
  },
  (Isolate isolate) async {
    // We are at our breakpoint with global=100.
    Instance result = await isolate.rootLibrary.evaluate('global') as Instance;
    print('global is $result');
    expect(result.type, equals('Instance'));
    expect(result.valueAsString, equals('100'));

    // Rewind the top stack frame.
    var result2 = await isolate.rewind(1);
    expect(result2['type'], equals('Success'));
  },
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  (Isolate isolate) async {
    var result = await isolate.resume();
    expect(result['type'], equals('Success'));
  },
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_0),
  stepOver,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  (Isolate isolate) async {
    // global still is equal to 100.  We did not execute "global++".
    Instance result = await isolate.rootLibrary.evaluate('global') as Instance;
    print('global is $result');
    expect(result.type, equals('Instance'));
    expect(result.valueAsString, equals('100'));

    // Rewind up to 'test'/
    var result2 = await isolate.rewind(3);
    expect(result2['type'], equals('Success'));
  },
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_D),
  (Isolate isolate) async {
    // Reset global to 0 and start again.
    Instance result =
        await isolate.rootLibrary.evaluate('global=0') as Instance;
    print('set global to $result');
    expect(result.type, equals('Instance'));
    expect(result.valueAsString, equals('0'));

    var result2 = await isolate.resume();
    expect(result2['type'], equals('Success'));
  },
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_0),
  stepOver,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  (Isolate isolate) async {
    // We are at our breakpoint with global=100.
    Instance result = await isolate.rootLibrary.evaluate('global') as Instance;
    print('global is $result');
    expect(result.type, equals('Instance'));
    expect(result.valueAsString, equals('100'));

    // Rewind the top 2 stack frames.
    var result2 = await isolate.rewind(2);
    expect(result2['type'], equals('Success'));
  },
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: test, extraArgs: [
      '--trace-rewind',
      '--no-prune-dead-locals',
      '--no-background-compilation',
      '--optimization-counter-threshold=10'
    ]);
