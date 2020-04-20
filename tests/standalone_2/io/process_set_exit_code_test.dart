// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=process_set_exit_code_script.dart

// Process test program to test process communication.

library ProcessSetExitCodeTest;

import "dart:io";
import "package:expect/expect.dart";
import "package:path/path.dart";

main() {
  var executable = Platform.executable;
  var exitCodeScript =
      Platform.script.resolve('process_set_exit_code_script.dart').toFilePath();
  Process.run(
          executable,
          []
            ..addAll(Platform.executableArguments)
            ..add(exitCodeScript))
      .then((result) {
    Expect.equals("standard out", result.stdout);
    Expect.equals("standard error", result.stderr);
    Expect.equals(25, result.exitCode);
  });
}
