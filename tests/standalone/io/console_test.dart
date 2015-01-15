// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:convert";
import "dart:io";

import "package:expect/expect.dart";

void main() {
  var script = Platform.script.resolve("console_script.dart").toFilePath();
  Process.run(Platform.executable,
              ['--checked', script],
              stdoutEncoding: ASCII,
              stderrEncoding: ASCII).then((result) {
                  print(result.stdout);
                  print(result.stderr);
    Expect.equals(1, result.exitCode);
    if (Platform.isWindows) {
      Expect.equals('stdout\r\n\r\ntuodts\r\nABCDEFGHIJKLM\r\n', result.stdout);
      Expect.equals('stderr\r\n\r\nrredts\r\nABCDEFGHIJKLM\r\n', result.stderr);
    } else {
      Expect.equals('stdout\n\ntuodts\nABCDEFGHIJKLM\n', result.stdout);
      Expect.equals('stderr\n\nrredts\nABCDEFGHIJKLM\n', result.stderr);
    }
  });
}
