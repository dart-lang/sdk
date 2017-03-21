// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'dart:developer';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

const alwaysInline = "AlwaysInline";
const noInline = "NeverInline";

int LINE_A = 35;
int LINE_B = 40;
int LINE_C = 43;
int LINE_D = 47;

int global = 0;

@noInline
b3(x) {
  int sum = 0;
  try {
    for (int i = 0; i < x; i++) {
      sum += x;
    }
  } catch (e) {
    print("caught $e");
  }
  if (global >= 100) {
    debugger();
  }
  global = global + 1;  // Line A
  return sum;
}

@alwaysInline
b2(x) => b3(x);  // Line B

@alwaysInline
b1(x) => b2(x);  // Line C

test() {
  while (true) {
    b1(10000);  // Line D
  }
}

var tests = [
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),

  (Isolate isolate) async {
    // We are not able to rewind frame 0.
    bool caughtException;
    try {
      await isolate.rewind(0);
      expect(false, isTrue, reason:'Unreachable');
    } on ServerRpcException catch(e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kCannotResume));
      expect(e.message, 'Frame must be in bounds [1..9]: saw 0');
    }
    expect(caughtException, isTrue);
  },

  (Isolate isolate) async {
    // We are not able to rewind frame 10.
    bool caughtException;
    try {
      await isolate.rewind(10);
      expect(false, isTrue, reason:'Unreachable');
    } on ServerRpcException catch(e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kCannotResume));
      expect(e.message, 'Frame must be in bounds [1..9]: saw 10');
    }
    expect(caughtException, isTrue);
  },

  (Isolate isolate) async {
    // We are at our breakpoint with global=100.
    var result = await isolate.rootLibrary.evaluate('global');
    print('global is $result');
    expect(result.type, equals('Instance'));
    expect(result.valueAsString, equals('100'));

    // Rewind the top stack frame.
    result = await isolate.rewind(1);
    expect(result['type'], equals('Success'));
  },

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),

  (Isolate isolate) async {
    var result = await isolate.resume();
    expect(result['type'], equals('Success'));
  },

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),

  (Isolate isolate) async {
    // global still is equal to 100.  We did not execute "global++".
    var result = await isolate.rootLibrary.evaluate('global');
    print('global is $result');
    expect(result.type, equals('Instance'));
    expect(result.valueAsString, equals('100'));

    // Resume again, for fun.
    result = await isolate.resume();
    expect(result['type'], equals('Success'));
  },

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),

  (Isolate isolate) async {
    // global is now 101.
    var result = await isolate.rootLibrary.evaluate('global');
    print('global is $result');
    expect(result.type, equals('Instance'));
    expect(result.valueAsString, equals('101'));

    // Rewind up to 'test'/
    result = await isolate.rewind(3);
    expect(result['type'], equals('Success'));
  },

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_D),

  (Isolate isolate) async {
    // Reset global to 0 and start again.
    var result = await isolate.rootLibrary.evaluate('global=0');
    print('set global to $result');
    expect(result.type, equals('Instance'));
    expect(result.valueAsString, equals('0'));

    result = await isolate.resume();
    expect(result['type'], equals('Success'));
  },

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),

  (Isolate isolate) async {
    // We are at our breakpoint with global=100.
    var result = await isolate.rootLibrary.evaluate('global');
    print('global is $result');
    expect(result.type, equals('Instance'));
    expect(result.valueAsString, equals('100'));

    // Rewind the top 2 stack frames.
    result = await isolate.rewind(2);
    expect(result['type'], equals('Success'));
  },

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
];


main(args) => runIsolateTests(args, tests, testeeConcurrent: test,
                              extraArgs:
                              ['--trace-rewind',
                               '--no-prune-dead-locals',
                               '--enable-inlining-annotations',
                               '--no-background-compilation',
                               '--optimization-counter-threshold=10']);
