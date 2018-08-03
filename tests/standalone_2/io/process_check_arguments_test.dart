// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:io";
import "process_test_util.dart";

test(args) {
  var future = Process.start(Platform.executable, args);
  future.then((process) {
    process.exitCode.then((exitCode) {
      Expect.equals(0, exitCode);
    });
    // Drain stdout and stderr.
    process.stdout.listen((_) {});
    process.stderr.listen((_) {});
  });
}

main() {
  // Get the Dart script file which checks arguments.
  var scriptFile =
      new File("tests/standalone_2/io/process_check_arguments_script.dart");
  if (!scriptFile.existsSync()) {
    scriptFile = new File(
        "../tests/standalone_2/io/process_check_arguments_script.dart");
  }
  test([scriptFile.path, '3', '0', 'a']);
  test([scriptFile.path, '3', '0', 'a b']);
  test([scriptFile.path, '3', '0', 'a\tb']);
  test([scriptFile.path, '3', '1', 'a\tb"']);
  test([scriptFile.path, '3', '1', 'a"\tb']);
  test([scriptFile.path, '3', '1', 'a"\t\\\\"b"']);
  test([scriptFile.path, '4', '0', 'a\tb', 'a']);
  test([scriptFile.path, '4', '0', 'a\tb', 'a\t\t\t\tb']);
  test([scriptFile.path, '4', '0', 'a\tb', 'a    b']);
}
