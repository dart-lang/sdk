// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to test process communication.

library ProcessSegfaultTest;

import "package:expect/expect.dart";
import "dart:io";
import "process_test_util.dart";

testExit() {
  var future =
      Process.start(getProcessTestFileName(), const ["0", "0", "1", "1"]);
  future.then((process) {
    process.exitCode.then((int exitCode) {
      Expect.isTrue(exitCode != 0);
    });
    process.stdout.listen((_) {});
    process.stderr.listen((_) {});
  });
}

testExitRun() {
  Process
      .run(getProcessTestFileName(), const ["0", "0", "1", "1"]).then((result) {
    Expect.isTrue(result.exitCode != 0);
    Expect.equals(result.stdout, '');
    Expect.equals(result.stderr, '');
  });
}

main() {
  testExit();
  testExitRun();
}
