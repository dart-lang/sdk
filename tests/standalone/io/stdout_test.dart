// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

import "package:expect/expect.dart";

void testTerminalSize() {
  if (stdout.hasTerminal) {
    Expect.notEquals(0, stdout.terminalColumns);
    Expect.notEquals(0, stdout.terminalLines);
  } else {
    Expect.throws(() => stdout.terminalColumns, (e) => e is StdoutException);
    Expect.throws(() => stdout.terminalLines, (e) => e is StdoutException);
  }
}


void main() {
  testTerminalSize();
}
