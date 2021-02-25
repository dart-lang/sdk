// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:developer';
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

const int LINE = 106;
const int LINE_A = 23;
const int LINE_B = 36;
const int LINE_C = 47;
const int LINE_D = 61;
const int LINE_E = 78;
const int LINE_F = 93;

// break statement
Stream<int> testBreak() async* {
  for (int t = 0; t < 10; t++) {
    try {
      if (t == 1) break;
      await throwException(); // LINE_A
    } catch (e) {} finally {
      yield t;
    }
  }
}

// return statement
Stream<int> testReturn() async* {
  for (int t = 0; t < 10; t++) {
    try {
      yield t;
      if (t == 1) return;
      await throwException(); // LINE_B
    } catch (e) {} finally {
      yield t;
    }
  }
}

// Multiple functions
Stream<int> testMultipleFunctions() async* {
  try {
    yield 0;
    await throwException(); // LINE_C
  } catch (e) {} finally {
    yield 1;
  }
}

// continue statement
Stream<int> testContinueSwitch() async* {
  int currentState = 0;
  switch (currentState) {
    case 0:
      {
        try {
          if (currentState == 1) continue label;
          await throwException(); // LINE_D
        } catch (e) {} finally {
          yield 0;
        }
        yield 1;
        break;
      }
    label:
    case 1:
      break;
  }
}

Stream<int> testNestFinally() async* {
  int i = 0;
  try {
    if (i == 1) return;
    await throwException(); //LINE_E
  } catch (e) {} finally {
    try {
      yield i;
    } finally {
      yield 1;
    }
    yield 1;
  }
}

Stream<int> testAsyncClosureInFinally() async* {
  int i = 0;
  try {
    if (i == 1) return;
    await throwException(); //LINE_F
  } catch (e) {} finally {
    inner() async {
      await Future.delayed(Duration(milliseconds: 10));
    }

    await inner;
    yield 1;
  }
}

Future<void> throwException() async {
  await Future.delayed(Duration(milliseconds: 10));
  throw new Exception(""); // LINE
}

code() async {
  await for (var x in testBreak()) {}
  await for (var x in testReturn()) {}
  await for (var x in testMultipleFunctions()) {}
  await for (var x in testContinueSwitch()) {}
  await for (var x in testNestFinally()) {}
  await for (var x in testAsyncClosureInFinally()) {}
}

var tests = <IsolateTest>[
  hasPausedAtStart,
  setBreakpointAtLine(LINE),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE),
  (Isolate isolate) async {
    // test break statement
    ServiceMap stack = await isolate.getStack();
    expect(stack['awaiterFrames'], isNotNull);
    expect(stack['awaiterFrames'].length, greaterThanOrEqualTo(2));

    // Check second top frame contains correct line number
    Script script = stack['awaiterFrames'][1].location.script;
    expect(script.tokenToLine(stack['awaiterFrames'][1].location.tokenPos),
        equals(LINE_A));
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE),
  (Isolate isolate) async {
    // test return statement
    ServiceMap stack = await isolate.getStack();
    expect(stack['awaiterFrames'], isNotNull);
    expect(stack['awaiterFrames'].length, greaterThanOrEqualTo(2));

    // Check second top frame contains correct line number
    Script script = stack['awaiterFrames'][1].location.script;
    expect(script.tokenToLine(stack['awaiterFrames'][1].location.tokenPos),
        equals(LINE_B));
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE),
  (Isolate isolate) async {
    // test break statement
    ServiceMap stack = await isolate.getStack();
    expect(stack['awaiterFrames'], isNotNull);
    expect(stack['awaiterFrames'].length, greaterThanOrEqualTo(2));

    // Check second top frame contains correct line number
    Script script = stack['awaiterFrames'][1].location.script;
    expect(script.tokenToLine(stack['awaiterFrames'][1].location.tokenPos),
        equals(LINE_C));
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE),
  (Isolate isolate) async {
    // test break statement
    ServiceMap stack = await isolate.getStack();
    expect(stack['awaiterFrames'], isNotNull);
    expect(stack['awaiterFrames'].length, greaterThanOrEqualTo(2));

    // Check second top frame contains correct line number
    Script script = stack['awaiterFrames'][1].location.script;
    expect(script.tokenToLine(stack['awaiterFrames'][1].location.tokenPos),
        equals(LINE_D));
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE),
  (Isolate isolate) async {
    // test nested finally statement
    ServiceMap stack = await isolate.getStack();
    expect(stack['awaiterFrames'], isNotNull);
    expect(stack['awaiterFrames'].length, greaterThanOrEqualTo(2));

    // Check second top frame contains correct line number
    Script script = stack['awaiterFrames'][1].location.script;
    expect(script.tokenToLine(stack['awaiterFrames'][1].location.tokenPos),
        equals(LINE_E));
  },
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE),
  (Isolate isolate) async {
    // test async closure within finally block
    ServiceMap stack = await isolate.getStack();
    expect(stack['awaiterFrames'], isNotNull);
    expect(stack['awaiterFrames'].length, greaterThanOrEqualTo(2));

    // Check second top frame contains correct line number
    Script script = stack['awaiterFrames'][1].location.script;
    expect(script.tokenToLine(stack['awaiterFrames'][1].location.tokenPos),
        equals(LINE_F));
  },
  resumeIsolate,
  hasStoppedAtExit
];

main(args) {
  runIsolateTestsSynchronous(args, tests,
      testeeConcurrent: code, pause_on_start: true, pause_on_exit: true);
}
