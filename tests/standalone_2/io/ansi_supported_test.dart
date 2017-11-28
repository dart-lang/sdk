// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import "package:expect/expect.dart";

testStdout(Stdout s) {
  try {
    s.supportsAnsiEscapes;
  } catch (e, st) {
    Expect.fail("$s.supportsAnsiEscapes threw: $e\n$st\n");
  }
  Expect.isNotNull(s.supportsAnsiEscapes);
  Expect.isTrue(s.supportsAnsiEscapes is bool);
  if (s.supportsAnsiEscapes) {
    s.writeln('\x1b[31mThis text has a red foreground using SGR.31.');
    s.writeln('\x1b[39mThis text has restored the foreground color.');
  } else {
    s.writeln('ANSI escape codes are not supported on this platform');
  }
}

main() {
  testStdout(stdout);
  testStdout(stderr);
  try {
    stdin.supportsAnsiEscapes;
  } catch (e, st) {
    Expect.fail("stdin.supportsAnsiEscapes threw: $e\n$st\n");
  }
  Expect.isNotNull(stdin.supportsAnsiEscapes);
  Expect.isTrue(stdin.supportsAnsiEscapes is bool);
}
