// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/models.dart' as M;
import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

const int LINE = 113;
const int LINE_A = 24;
const int LINE_B = 38;
const int LINE_C = 50;
const int LINE_D = 65;
const int LINE_E = 83;
const int LINE_F = 99;

// break statement
Stream<int> testBreak() async* {
  for (int t = 0; t < 10; t++) {
    try {
      if (t == 1) break;
      await throwException(); // LINE_A
    } catch (e) {
    } finally {
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
    } catch (e) {
    } finally {
      yield t;
    }
  }
}

// Multiple functions
Stream<int> testMultipleFunctions() async* {
  try {
    yield 0;
    await throwException(); // LINE_C
  } catch (e) {
  } finally {
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
        } catch (e) {
        } finally {
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
  } catch (e) {
  } finally {
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
  } catch (e) {
  } finally {
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
  await for (var _ in testBreak()) {}
  await for (var _ in testReturn()) {}
  await for (var _ in testMultipleFunctions()) {}
  await for (var _ in testContinueSwitch()) {}
  await for (var _ in testNestFinally()) {}
  await for (var _ in testAsyncClosureInFinally()) {}
}

var tests = <IsolateTest>[
  hasPausedAtStart,
  setBreakpointAtLine(LINE),
  resumeIsolate,
  for (var line in [LINE_A, LINE_B, LINE_C, LINE_D, LINE_E, LINE_F]) ...[
    hasStoppedAtBreakpoint,
    stoppedAtLine(LINE),
    _expectSecondFrameFromTheTopToBeAt(line),
    resumeIsolate,
  ],
  hasStoppedAtExit
];

Future<void> Function(Isolate) _expectSecondFrameFromTheTopToBeAt(int line) {
  return (isolate) async {
    ServiceMap stack = await isolate.getStack();
    expect(stack['asyncCausalFrames'], isNotNull);
    expect(stack['asyncCausalFrames'].length, greaterThanOrEqualTo(3));

    // Check second top frame contains correct line number.
    final frames = (stack['asyncCausalFrames'] as List).cast<Frame>();
    expect(frames[0].kind, M.FrameKind.regular);
    final script0 = frames[0].location!.script;
    expect(script0.tokenToLine(frames[0].location!.tokenPos), equals(LINE));
    expect(frames[1].kind, M.FrameKind.asyncSuspensionMarker);
    expect(frames[2].location, isNotNull);
    expect(frames[2].kind, M.FrameKind.asyncCausal);
    final script2 = frames[2].location!.script;
    expect(script2.tokenToLine(frames[2].location!.tokenPos), equals(line));
  };
}

main(args) {
  runIsolateTestsSynchronous(args, tests,
      testeeConcurrent: code, pause_on_start: true, pause_on_exit: true);
}
