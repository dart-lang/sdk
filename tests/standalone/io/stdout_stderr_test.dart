// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=stdout_stderr_test_script.dart

import "package:expect/expect.dart";
import "dart:async";
import "dart:convert";
import "dart:io";

/// Execute "stdout_stderr_test_script.dart" with `command` as an argument and
/// return the commands stdout as a list of bytes.
List<int> runTest(String lineTerminatorMode, String encoding, String command) {
  final result = Process.runSync(
      Platform.executable,
      []
        ..addAll(Platform.executableArguments)
        ..add('--verbosity=warning')
        ..add(Platform.script
            .resolve('stdout_stderr_test_script.dart')
            .toFilePath())
        ..add('--eol=$lineTerminatorMode')
        ..add('--encoding=$encoding')
        ..add(command),
      stdoutEncoding: null);

  if (result.exitCode != 0) {
    throw AssertionError(
        'unexpected exit code for command $command: ${result.stderr}');
  }
  return result.stdout;
}

const winEol = [13, 10];
const posixEol = [10];

void testByteListHello() {
  // add([104, 101, 108, 108, 111, 10])
  final expected = [104, 101, 108, 108, 111, 10];
  Expect.listEquals(expected, runTest("unix", "ascii", "byte-list-hello"));
  Expect.listEquals(expected, runTest("windows", "ascii", "byte-list-hello"));
  Expect.listEquals(expected, runTest("default", "ascii", "byte-list-hello"));
}

void testByteListAllo() {
  // add([97, 108, 108, 244, 10])
  final expected = [97, 108, 108, 244, 10];
  Expect.listEquals(expected, runTest("unix", "latin1", "byte-list-allo"));
  Expect.listEquals(expected, runTest("windows", "latin1", "byte-list-allo"));
  Expect.listEquals(expected, runTest("default", "latin1", "byte-list-allo"));
}

void testStreamHello() {
  // add([104, 101, 108, 108, 111, 10])
  final expected = [104, 101, 108, 108, 111, 10];
  Expect.listEquals(expected, runTest("unix", "ascii", "stream-hello"));
  Expect.listEquals(expected, runTest("windows", "ascii", "stream-hello"));
  Expect.listEquals(expected, runTest("default", "ascii", "stream-hello"));
}

void testStreamAllo() {
  // add([97, 108, 108, 244, 10])
  final expected = [97, 108, 108, 244, 10];
  Expect.listEquals(expected, runTest("unix", "latin1", "stream-allo"));
  Expect.listEquals(expected, runTest("windows", "latin1", "stream-allo"));
  Expect.listEquals(expected, runTest("default", "latin1", "stream-allo"));
}

void testStringHello() {
  // write('hello\n')
  final expectedPosix = [104, 101, 108, 108, 111, ...posixEol];
  final expectedWin = [104, 101, 108, 108, 111, ...winEol];

  Expect.listEquals(expectedPosix, runTest("unix", "ascii", "string-hello"));
  Expect.listEquals(expectedWin, runTest("windows", "ascii", "string-hello"));
  Expect.listEquals(expectedPosix, runTest("default", "ascii", "string-hello"));
}

void testStringAllo() {
  // write('hello\n')
  final expectedPosix = [97, 108, 108, 244, ...posixEol];
  final expectedWin = [97, 108, 108, 244, ...winEol];

  Expect.listEquals(expectedPosix, runTest("unix", "ascii", "string-allo"));
  Expect.listEquals(expectedWin, runTest("windows", "ascii", "string-allo"));
  Expect.listEquals(expectedPosix, runTest("default", "ascii", "string-allo"));
}

void testStringInternalLineFeeds() {
  // write('l1\nl2\nl3')
  final expectedPosix = [108, 49, ...posixEol, 108, 50, ...posixEol, 108, 51];
  final expectedWin = [108, 49, ...winEol, 108, 50, ...winEol, 108, 51];

  Expect.listEquals(
      expectedPosix, runTest("unix", "ascii", "string-internal-linefeeds"));
  Expect.listEquals(
      expectedWin, runTest("windows", "ascii", "string-internal-linefeeds"));
  Expect.listEquals(
      expectedPosix, runTest("default", "ascii", "string-internal-linefeeds"));
}

void testStringCarriageReturns() {
  // write("l1\rl2\rl3\r")
  final expected = [108, 49, 13, 108, 50, 13, 108, 51, 13];
  Expect.listEquals(
      expected, runTest("unix", "ascii", "string-internal-carriagereturns"));
  Expect.listEquals(
      expected, runTest("windows", "ascii", "string-internal-carriagereturns"));
  Expect.listEquals(
      expected, runTest("default", "ascii", "string-internal-carriagereturns"));
}

void testStringCarriageReturnLinefeeds() {
  // ""l1\r\nl2\r\nl3\r\n""
  final expected = [108, 49, ...winEol, 108, 50, ...winEol, 108, 51, ...winEol];
  Expect.listEquals(expected,
      runTest("unix", "ascii", "string-internal-carriagereturn-linefeeds"));
  Expect.listEquals(expected,
      runTest("windows", "ascii", "string-internal-carriagereturn-linefeeds"));
  Expect.listEquals(expected,
      runTest("default", "ascii", "string-internal-carriagereturn-linefeeds"));
}

void testStringCarriageReturnLinefeedsSeperateWrite() {
  // write("l1\r");
  // write("\nl2");
  final expected = [108, 49, ...winEol, 108, 50];
  Expect.listEquals(
      expected,
      runTest(
          "unix", "ascii", "string-carriagereturn-linefeed-seperate-write"));
  Expect.listEquals(
      expected,
      runTest(
          "windows", "ascii", "string-carriagereturn-linefeed-seperate-write"));
  Expect.listEquals(
      expected,
      runTest(
          "default", "ascii", "string-carriagereturn-linefeed-seperate-write"));
}

void testStringCarriageReturnFollowedByWriteln() {
  // write("l1\r");
  // writeln();
  final expectedPosix = [108, 49, 13, ...posixEol];
  final expectedWin = [108, 49, 13, ...winEol];

  Expect.listEquals(
      expectedPosix, runTest("unix", "ascii", "string-carriagereturn-writeln"));
  Expect.listEquals(expectedWin,
      runTest("windows", "ascii", "string-carriagereturn-writeln"));
  Expect.listEquals(expectedPosix,
      runTest("default", "ascii", "string-carriagereturn-writeln"));
}

void testWriteCharCodeLineFeed() {
  // write("l1");
  // writeCharCode(10);
  final expectedPosix = [108, 49, ...posixEol];
  final expectedWin = [108, 49, ...winEol];

  Expect.listEquals(
      expectedPosix, runTest("unix", "ascii", "write-char-code-linefeed"));
  Expect.listEquals(
      expectedWin, runTest("windows", "ascii", "write-char-code-linefeed"));
  Expect.listEquals(
      expectedPosix, runTest("default", "ascii", "write-char-code-linefeed"));
}

void testWriteCharCodeLineFeedFollowingCarriageReturn() {
  // write("1\r");
  // writeCharCode(10);
  final expected = [108, 49, ...winEol];

  Expect.listEquals(
      expected,
      runTest(
          "unix", "ascii", "write-char-code-linefeed-after-carriagereturn"));
  Expect.listEquals(
      expected,
      runTest(
          "windows", "ascii", "write-char-code-linefeed-after-carriagereturn"));
  Expect.listEquals(
      expected,
      runTest(
          "default", "ascii", "write-char-code-linefeed-after-carriagereturn"));
}

void testInvalidLineTerminator() {
  Expect.throwsArgumentError(() => stdout.lineTerminator = "\r");
}

void main() {
  testByteListHello();
  testByteListAllo();
  testStreamHello();
  testStreamAllo();
  testStringHello();
  testStringInternalLineFeeds();
  testStringCarriageReturns();
  testStringCarriageReturnLinefeeds();
  testStringCarriageReturnLinefeedsSeperateWrite();
  testStringCarriageReturnFollowedByWriteln();
  testWriteCharCodeLineFeed();
  testWriteCharCodeLineFeedFollowingCarriageReturn();
  testInvalidLineTerminator();
}
