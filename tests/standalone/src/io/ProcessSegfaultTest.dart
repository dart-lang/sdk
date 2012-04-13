// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to test process communication.

#library("ProcessSegfaultTest");
#import("dart:io");
#source("ProcessTestUtil.dart");

testExit() {
  Process process = new Process.start(getProcessTestFileName(),
                                      const ["0", "0", "1", "1"]);

  process.onExit = (int exitCode) {
    Expect.isTrue(exitCode != 0);
    process.close();
  };
}


testExitRun() {
  Process process = new Process.run(getProcessTestFileName(),
                                    const ["0", "0", "1", "1"],
                                    null,
                                    (exit, out, err) {
    Expect.isTrue(exit != 0);
    Expect.equals(out, '');
    Expect.equals(err, '');
  });
}


main() {
  testExit();
  testExitRun();
}
