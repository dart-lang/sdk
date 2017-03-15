// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import "package:expect/expect.dart";

main() {
  try {
    Platform.ansiSupported;
  } catch (e, s) {
    Expect.fail("Platform.ansiSupported threw: $e\n$s\n");
  }
  Expect.isNotNull(Platform.ansiSupported);
  Expect.isTrue(Platform.ansiSupported is bool);
  if (stdout.hasTerminal && Platform.ansiSupported) {
    stdout.writeln('\x1b[31mThis text has a red foreground using SGR.31.');
    stdout.writeln('\x1b[39mThis text has restored the foreground color.');
  } else {
    stdout.writeln('ANSI codes not supported on this platform');
  }
}
