// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to test process communication.

library ProcessKillTest;

import 'dart:io';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

import "process_test_util.dart";

testKill() {
  asyncStart();
  // Start a process that will hang waiting for input until killed.
  Process.start(getProcessTestFileName(), const ["0", "1", "0", "0"]).then((p) {
    p.exitCode.then((exitCode) {
      // Process killed from the side so exit code is not 0.
      Expect.isTrue(exitCode != 0);
      // Killing a process that is already dead returns false.
      Expect.isFalse(p.kill());
      asyncEnd();
    });
    Expect.isTrue(p.kill());
  });
}

testKillPid() {
  asyncStart();
  // Start a process that will hang waiting for input until killed.
  Process.start(getProcessTestFileName(), const ["0", "1", "0", "0"]).then((p) {
    p.exitCode.then((exitCode) {
      // Process killed from the side so exit code is not 0.
      Expect.isTrue(exitCode != 0);
      // Killing a process that is already dead returns false.
      Expect.isFalse(Process.killPid(p.pid));
      asyncEnd();
    });
    Expect.isTrue(Process.killPid(p.pid));
  });
}

main() {
  testKill();
  testKillPid();
}
