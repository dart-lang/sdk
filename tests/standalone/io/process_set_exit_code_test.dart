// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to test process communication.

library ProcessSetExitCodeTest;

import "package:expect/expect.dart";
import "dart:io";

main() {
  var options = new Options();
  var executable = options.executable;
  var script = options.script;
  var scriptDirectory = new Path(script).directoryPath;
  var exitCodeScript =
      scriptDirectory.append('process_set_exit_code_script.dart');
  Process.run(executable, [exitCodeScript.toNativePath()]).then((result) {
    Expect.equals("standard out", result.stdout);
    Expect.equals("standard error", result.stderr);
    Expect.equals(25, result.exitCode);
  });
}
