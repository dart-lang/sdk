// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';

import 'package:expect/expect.dart';

const String scriptName = 'zone_callback_stack_traces_test.dart';

Future<void> foo() async {}

Future<void> bar() async {
  await foo();
}

Future<void> runTest() {
  final Zone testZone = Zone.current.fork(
      specification: ZoneSpecification(
          registerUnaryCallback: _registerUnaryCallback,
          registerBinaryCallback: _registerBinaryCallback));
  return testZone.run(bar);
}

StackTrace registerUnaryCallbackStackTrace;
StackTrace registerBinaryCallbackStackTrace;

ZoneUnaryCallback<R, T> _registerUnaryCallback<R, T>(
    Zone self, ZoneDelegate parent, Zone zone, R Function(T) f) {
  final stackTrace = StackTrace.current;
  print('registerUnaryCallback got stack trace:');
  print(stackTrace);
  if (stackTrace.toString().contains('bar')) {
    Expect.isNull(registerUnaryCallbackStackTrace);
    registerUnaryCallbackStackTrace = stackTrace;
  }
  return parent.registerUnaryCallback(zone, f);
}

ZoneBinaryCallback<R, T1, T2> _registerBinaryCallback<R, T1, T2>(
    Zone self, ZoneDelegate parent, Zone zone, R Function(T1, T2) f) {
  final stackTrace = StackTrace.current;
  print('registerBinaryCallback got stack trace:');
  print(stackTrace);
  if (stackTrace.toString().contains('bar')) {
    Expect.isNull(registerBinaryCallbackStackTrace);
    registerBinaryCallbackStackTrace = stackTrace;
  }
  return parent.registerBinaryCallback(zone, f);
}

void verifyStackTrace(List<String> expected, StackTrace stackTrace) {
  final List<String> actual = stackTrace
      .toString()
      .split('\n')
      .where((entry) => entry.contains(scriptName))
      .toList();
  print('Expected:\n${expected.join('\n')}');
  print('Actual:\n${actual.join('\n')}');
  Expect.equals(expected.length, actual.length);
  for (int i = 0; i < expected.length; ++i) {
    if (!RegExp(expected[i]).hasMatch(actual[i])) {
      Expect.fail("Stack trace entry $i doesn't match:\n"
          "  expected: ${expected[i]}\n  actual: ${actual[i]}");
    }
  }
}

main() async {
  await runTest();
  verifyStackTrace([
    r'^#\d+      _registerUnaryCallback \(.*zone_callback_stack_traces_test.dart:32(:33)?\)$',
    r'^#\d+      bar \(.*zone_callback_stack_traces_test.dart:16(:3)?\)$',
    r'^#\d+      runTest \(.*zone_callback_stack_traces_test.dart:24(:19)?\)$',
    r'^#\d+      main \(.*zone_callback_stack_traces_test.dart:72(:9)?\)$',
  ], registerUnaryCallbackStackTrace);

  verifyStackTrace([
    r'^#\d+      _registerBinaryCallback \(.*zone_callback_stack_traces_test.dart:44(:33)?\)$',
    r'^#\d+      bar \(.*zone_callback_stack_traces_test.dart:16(:3)?\)$',
    r'^#\d+      runTest \(.*zone_callback_stack_traces_test.dart:24(:19)?\)$',
    r'^#\d+      main \(.*zone_callback_stack_traces_test.dart:72(:9)?\)$',
  ], registerBinaryCallbackStackTrace);
}
