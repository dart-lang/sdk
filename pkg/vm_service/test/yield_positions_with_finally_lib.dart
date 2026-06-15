// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: empty_catches

import 'common/test_helper.dart';

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
  final int currentState = 0;
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
  final int i = 0;
  try {
    if (i == 1) return;
    await throwException(); // LINE_E
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
  final int i = 0;
  try {
    if (i == 1) return;
    await throwException(); // LINE_F
  } catch (e) {
  } finally {
    Future<void> inner() async {
      await Future.delayed(Duration(milliseconds: 10));
    }

    await inner();
    yield 1;
  }
}

Future<void> throwException() async {
  await Future.delayed(Duration(milliseconds: 10));
  throw Exception(''); // LINE_G
}

Future<void> code() async {
  await for (var _ in testBreak()) {}
  await for (var _ in testReturn()) {}
  await for (var _ in testMultipleFunctions()) {}
  await for (var _ in testContinueSwitch()) {}
  await for (var _ in testNestFinally()) {}
  await for (var _ in testAsyncClosureInFinally()) {}
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
