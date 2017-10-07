// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to test process communication.

library ProcessExitTest;

import "dart:io";
import "package:expect/expect.dart";
import "process_test_util.dart";

testExit() {
  var future =
      Process.start(getProcessTestFileName(), const ["0", "0", "99", "0"]);
  future.then((process) {
    process.exitCode.then((int exitCode) {
      Expect.equals(exitCode, 99);
    });
    process.stdout.listen((_) {});
    process.stderr.listen((_) {});
  });
}

testExitRun() {
  Process.run(getProcessTestFileName(), const ["0", "0", "99", "0"]).then(
      (result) {
    Expect.equals(result.exitCode, 99);
    Expect.equals(result.stdout, '');
    Expect.equals(result.stderr, '');
  });
}

main() {
  testExit();
  testExitRun();
}
