// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to test closed stdin from child process.

import "package:expect/expect.dart";
import "dart:io";
import "dart:isolate";

import "process_test_util.dart";

main() {
  // Running dart without arguments makes it close right away.
  var future = Process.start(Platform.executable, []);
  future.then((process) {
    process.stdin.done.catchError((e) {
      // Accept errors on stdin.
    });

    // Drain stdout and stderr.
    process.stdout.listen((_) {});
    process.stderr.listen((_) {});

    // Write to the stdin after the process is terminated to test
    // writing to a broken pipe.
    process.exitCode.then((code) {
      process.stdin.add([0]);
    });
  });
}
