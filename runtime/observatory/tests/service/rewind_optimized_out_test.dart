// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:test/test.dart';

import 'package:observatory/service_io.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

// AUTOGENERATED START
//
// Update these constants by running:
//
// dart pkg/vm_service/test/update_line_numbers.dart runtime/observatory/tests/service/rewind_optimized_out_test.dart
//
const LINE_0 = 39;
const LINE_A = 41;
const LINE_B = 46;
const LINE_C = 49;
const LINE_D = 53;
// AUTOGENERATED END

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
    // We are at our breakpoint with global=100.
    Instance result = await isolate.rootLibrary.evaluate('global') as Instance;
    print('global is $result');
    expect(result.type, equals('Instance'));
    expect(result.valueAsString, equals('100'));

    // Rewind the top stack frame.
    bool caughtException = false;
    try {
      result = await isolate.rewind(1);
      expect(false, isTrue, reason: 'Unreachable');
    } on ServerRpcException catch (e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kCannotResume));
      expect(
          e.message,
          startsWith('Cannot rewind to frame 1 due to conflicting compiler '
              'optimizations. Run the vm with --no-prune-dead-locals '
              'to disallow these optimizations. Next valid rewind '
              'frame is '));
    }
    expect(caughtException, isTrue);
  },
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: test, extraArgs: [
      '--trace-rewind',
      '--prune-dead-locals',
      '--no-background-compilation',
      '--optimization-counter-threshold=10'
    ]);
