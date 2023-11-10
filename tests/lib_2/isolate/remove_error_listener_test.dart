// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// @dart = 2.9
//
// Test that removing error listener makes exception throwing unhandled.

import 'dart:io';
import 'dart:isolate';

import "package:expect/expect.dart";

void main(List<String> args) {
  if (args.length == 0) {
    final result = Process.runSync(Platform.executable, [
      ...Platform.executableArguments,
      Platform.script.toFilePath(),
      'child'
    ]);
    Expect.isTrue(result.stderr.contains(
        "Unhandled exception:${Platform.lineTerminator}Exception: Oops!"));
    return;
  }
  {
    final port = ReceivePort();
    Isolate.current.addErrorListener(port.sendPort);
    Isolate.current.removeErrorListener(port.sendPort);
    port.close();
    throw Exception('Oops!');
  }
}
