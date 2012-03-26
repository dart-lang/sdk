// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to test process communication.

#import("dart:io");

class ProcessStartExceptionTest {

  static void testStartError() {
    Process process =
        new Process.start("__path_to_something_that_should_not_exist__",
                          const []);

    process.onExit = (int exitCode) {
      Expect.fail("exit handler called");
    };

    process.onError = (ProcessException e) {
      Expect.equals(2, e.errorCode, e.toString());
    };
  }
}

main() {
  ProcessStartExceptionTest.testStartError();
}
