// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

import "package:expect/expect.dart";

void testTerminalSize(std) {
  if (std.hasTerminal) {
    Expect.notEquals(0, std.terminalColumns);
    Expect.notEquals(0, std.terminalLines);
  } else {
    Expect.throws(() => std.terminalColumns, (e) => e is StdoutException);
    Expect.throws(() => std.terminalLines, (e) => e is StdoutException);
  }
}

void main() {
  testTerminalSize(stdout);
  testTerminalSize(stderr);
}
