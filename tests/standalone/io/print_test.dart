// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=print_test_script.dart

/// Tests the `dart:core` `print` function.
///
/// The actual print code is in "print_test_script.dart" and the output is
/// validated in this test.

import 'dart:io';

import "package:expect/expect.dart";

final nl = Platform.isWindows ? [13, 10] : [10];

/// Execute "print_test_script.dart" with `command` as an argument and return
/// the commands stdout as a list of bytes.
List<int> runTest(String command) {
  final result = Process.runSync(
      Platform.executable,
      []
        ..addAll(Platform.executableArguments)
        ..add('--verbosity=warning')
        ..add(Platform.script.resolve('print_test_script.dart').toFilePath())
        ..add(command),
      stdoutEncoding: null);

  if (result.exitCode != 0) {
    throw AssertionError(
        'unexpected exit code for command $command: ${result.stderr}');
  }
  return result.stdout;
}

void testSimpleString() {
  // "Hello World!"
  final expected = [72, 101, 108, 108, 111, 32, 87, 111, 114, 108, 100, ...nl];
  Expect.listEquals(expected, runTest("simple-string"));
}

void testStringInternalLineEnding() {
  // "l1\nl2\nl3"
  final expected = [108, 49, ...nl, 108, 50, ...nl, 108, 51, ...nl];
  Expect.listEquals(expected, runTest("string-internal-linefeeds"));
}

void testStringCarriageReturns() {
  // "l1\rl2\rl3\r"
  final expected = [108, 49, 13, 108, 50, 13, 108, 51, 13, ...nl];
  Expect.listEquals(expected, runTest("string-internal-carriagereturns"));
}

void testStringCarriageReturnLinefeeds() {
  // ""l1\r\nl2\r\nl3\r\n""
  // Notice on Windows this will result in `\r\n` => `\r\r\n'
  final expected = [108, 49, 13, ...nl, 108, 50, 13, ...nl, 108, 51, 13, ...nl];
  Expect.listEquals(
      expected, runTest("string-internal-carriagereturn-linefeeds"));
}

void testObjectInternalLineEnding() {
  // Object.toString() => "l1\nl2\nl3"
  final expected = [108, 49, ...nl, 108, 50, ...nl, 108, 51, ...nl];
  Expect.listEquals(expected, runTest("object-internal-linefeeds"));
}

void main() {
  testSimpleString();
  testStringInternalLineEnding();
  testStringCarriageReturns();
  testObjectInternalLineEnding();
}
