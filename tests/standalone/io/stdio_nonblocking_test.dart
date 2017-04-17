// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=stdio_nonblocking_script.dart

import "dart:convert";
import "dart:io";

import "package:expect/expect.dart";

void main() {
  var script =
      Platform.script.resolve("stdio_nonblocking_script.dart").toFilePath();
  Process
      .run(Platform.executable, [script],
          stdoutEncoding: ASCII, stderrEncoding: ASCII)
      .then((result) {
    print(result.stdout);
    print(result.stderr);
    Expect.equals(1, result.exitCode);
    Expect.equals('stdout\n\ntuodts\nABCDEFGHIJKLM\n', result.stdout);
    Expect.equals('stderr\n\nrredts\nABCDEFGHIJKLM\n', result.stderr);
  });
}
