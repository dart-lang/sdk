// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:io");
#source("ProcessTestUtil.dart");

test(args) {
  Process process = new Process.start(getDartFileName(), args);
  // Wait for the process to exit and then check result.
  process.onExit = (exitCode) {
    Expect.equals(0, exitCode);
    process.close();
  };
}

main() {
  // Get the Dart script file which checks arguments.
  var scriptFile =
    new File("tests/standalone/src/io/ProcessCheckArgumentsScript.dart");
  if (!scriptFile.existsSync()) {
    scriptFile =
        new File("../tests/standalone/src/io/ProcessCheckArgumentsScript.dart");
  }
  test([scriptFile.name, '3', '0', 'a']);
  test([scriptFile.name, '3', '0', 'a b']);
  test([scriptFile.name, '3', '0', 'a\tb']);
  test([scriptFile.name, '3', '1', 'a\tb"']);
  test([scriptFile.name, '3', '1', 'a"\tb']);
  test([scriptFile.name, '3', '1', 'a"\t\\\\"b"']);
  test([scriptFile.name, '4', '0', 'a\tb', 'a']);
  test([scriptFile.name, '4', '0', 'a\tb', 'a\t\t\t\tb']);
  test([scriptFile.name, '4', '0', 'a\tb', 'a    b']);
}

