// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

import "package:expect/expect.dart";

void fiddleWithEchoMode() {
  final bool echoMode = stdin.echoMode;
  stdin.echoMode = false;
  stdin.echoMode = true;
  stdin.echoMode = echoMode;
}

void main() {
  Expect.isNotNull(stdin.hasTerminal);
  Expect.isTrue(stdin.hasTerminal is bool);
  if (stdin.hasTerminal) {
    fiddleWithEchoMode();
  } else {
    Expect.throws(() {
      fiddleWithEchoMode();
    }, (e) => e is StdinException);
  }
}
