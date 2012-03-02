// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to test process communication.

#library("ProcessExitTest");
#import("dart:io");
#source("ProcessTestUtil.dart");

class ProcessExitTest {
  static void testExit() {
    Process process = new Process.start(getProcessTestFileName(),
                                        const ["0", "0", "99", "0"]);

    process.onExit = (int exitCode) {
      Expect.equals(exitCode, 99);
      process.close();
    };
  }
}

main() {
  ProcessExitTest.testExit();
}
