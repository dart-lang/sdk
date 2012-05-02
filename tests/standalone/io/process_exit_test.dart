// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to test process communication.

#library("ProcessExitTest");
#import("dart:io");
#source("process_test_util.dart");

testExit() {
  Process process = new Process.start(getProcessTestFileName(),
                                      const ["0", "0", "99", "0"]);

  process.onExit = (int exitCode) {
    Expect.equals(exitCode, 99);
    process.close();
  };
}

testExitRun() {
  Process process = new Process.run(getProcessTestFileName(),
                                    const ["0", "0", "99", "0"],
                                    null,
                                    (exit, out, err) {
    Expect.equals(exit, 99);
    Expect.equals(out, '');
    Expect.equals(err, '');
  });
}

main() {
  testExit();
  testExitRun();
}
