// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:expect/expect.dart';
import 'package:expect/matchers_lite.dart';

Matcher startsWith(String expected) {
  return (Object actual) {
    if (actual is String) {
      Expect.equals(
          expected, actual.substring(0, min(expected.length, actual.length)));
      return;
    }
    Expect.fail('Expected String.');
  };
}

void assertStack(Map expected, StackTrace stack_trace) {
  final List<String> frames = stack_trace.toString().split('\n');
  for (int i in expected.keys) {
    expect(frames[i], startsWith(expected[i]));
  }
}

Future<void> doTest(Future f(), Map<int, String> expected_stack) async {
  // Caller catches exception.
  try {
    await f();
    Expect.fail('No exception thrown!');
  } on String catch (e, s) {
    assertStack(expected_stack, s);
  }

  // Caller catches but a then is set.
  try {
    await f().then((e) {
      // Ignore.
    });
    Expect.fail('No exception thrown!');
  } on String catch (e, s) {
    assertStack(expected_stack, s);
  }

  // Caller doesn't catch, but we have a catchError set.
  StackTrace stack_trace;
  await f().catchError((e, s) {
    stack_trace = s;
  });
  assertStack(expected_stack, stack_trace);
}

// Test functions:

Future<void> throwSync() {
  throw '';
}

Future<void> throwAsync() async {
  await 0;
  throw '';
}

// ----
// Scenario: All async functions yielded at least once before throw:
// ----
Future<void> allYield() async {
  await 0;
  await allYield2();
}

Future<void> allYield2() async {
  await 0;
  await allYield3();
}

Future<void> allYield3() async {
  await 0;
  throwSync();
}

// For: --causal-async-stacks
Map<int, String> allYieldMapCausal = {
  0: '#0      throwSync ',
  1: '#1      allYield3 ',
  2: '<asynchronous suspension>',
  3: '#2      allYield2 ',
  4: '<asynchronous suspension>',
  5: '#3      allYield ',
  4: '<asynchronous suspension>',
  // Callers, like doTest and main ..
};

// For: --no-causal-async-stacks
Map<int, String> allYieldMapNoCausal = {
  0: '#0      throwSync ',
  1: '#1      allYield3 ',
  2: '#2      _RootZone.runUnary ',
  // The rest are more Dart internal async mechanisms..
};

// ----
// Scenario: None of the async functions yieled before the throw:
// ----
Future<void> noYields() async {
  await noYields2();
}

Future<void> noYields2() async {
  await noYields3();
}

Future<void> noYields3() async {
  throwSync();
}

// For: --causal-async-stacks
Map<int, String> noYieldsMapCausal = {
  0: '#0      throwSync ',
  1: '#1      noYields3 ',
  2: '#2      noYields2 ',
  3: '#3      noYields ',
  // Callers, like doTest and main ..
};

// For: --no-causal-async-stacks
Map<int, String> noYieldsMapNoCausal = {
  0: '#0      throwSync ',
  1: '#1      noYields3 ',
  // Skip: _AsyncAwaitCompleter.start
  3: '#3      noYields3 ',
  4: '#4      noYields2 ',
  // Skip: _AsyncAwaitCompleter.start
  6: '#6      noYields2 ',
  7: '#7      noYields ',
  // Skip: _AsyncAwaitCompleter.start
  9: '#9      noYields ',
  // Calling functions like doTest and main ..
};

// ----
// Scenario: Mixed yielding and non-yielding frames:
// ----
Future<void> mixedYields() async {
  await mixedYields2();
}

Future<void> mixedYields2() async {
  await 0;
  await mixedYields3();
}

Future<void> mixedYields3() async {
  return throwAsync();
}

// For: --causal-async-stacks
Map<int, String> mixedYieldsMapCausal = {
  0: '#0      throwAsync ',
  1: '<asynchronous suspension>',
  2: '#1      mixedYields3 ',
  3: '#2      mixedYields2 ',
  4: '<asynchronous suspension>',
  5: '#3      mixedYields ',
  // Callers, like doTest and main ..
};

// For: --no-causal-async-stacks
Map<int, String> mixedYieldsMapNoCausal = {
  0: '#0      throwAsync ',
  1: '#1      _RootZone.runUnary ',
  // The rest are more Dart internal async mechanisms..
};

// ----
// Scenario: Non-async frame:
// ----
Future<void> syncSuffix() async {
  await syncSuffix2();
}

Future<void> syncSuffix2() async {
  await 0;
  await syncSuffix3();
}

Future<void> syncSuffix3() {
  return throwAsync();
}

// For: --causal-async-stacks
Map<int, String> syncSuffixMapCausal = {
  0: '#0      throwAsync ',
  1: '<asynchronous suspension>',
  2: '#1      syncSuffix3 ',
  3: '#2      syncSuffix2 ',
  4: '<asynchronous suspension>',
  5: '#3      syncSuffix ',
  // Callers, like doTest and main ..
};

// For: --no-causal-async-stacks
Map<int, String> syncSuffixMapNoCausal = {
  0: '#0      throwAsync ',
  1: '#1      _RootZone.runUnary ',
  // The rest are more Dart internal async mechanisms..
};

// ----
// Scenario: Caller is non-async, has no upwards stack:
// ----

Future nonAsyncNoStack() async => await nonAsyncNoStack1();

Future nonAsyncNoStack1() async => await nonAsyncNoStack2();

Future nonAsyncNoStack2() async => Future.value(0).then((_) => throwAsync());

// For: --causal-async-stacks
Map<int, String> nonAsyncNoStackMapCausal = {
  0: '#0      throwAsync ',
  1: '<asynchronous suspension>',
  2: '#1      nonAsyncNoStack2.<anonymous closure> ',
  3: '#2      _RootZone.runUnary ',
  // The rest are more Dart internal async mechanisms..
};

// For: --no-causal-async-stacks
Map<int, String> nonAsyncNoStackMapNoCausal = {
  0: '#0      throwAsync ',
  1: '#1      _RootZone.runUnary ',
  // The rest are more Dart internal async mechanisms..
};

// ----
// Test "Suites":
// ----

Future<void> doTestsCausal() async {
  await doTest(allYield, allYieldMapCausal);
  await doTest(noYields, noYieldsMapCausal);
  await doTest(mixedYields, mixedYieldsMapCausal);
  await doTest(syncSuffix, syncSuffixMapCausal);
  await doTest(nonAsyncNoStack, nonAsyncNoStackMapCausal);
}

Future<void> doTestsNoCausal() async {
  await doTest(allYield, allYieldMapNoCausal);
  await doTest(noYields, noYieldsMapNoCausal);
  await doTest(mixedYields, mixedYieldsMapNoCausal);
  await doTest(syncSuffix, syncSuffixMapNoCausal);
  await doTest(nonAsyncNoStack, nonAsyncNoStackMapNoCausal);
}
