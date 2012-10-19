// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to test closed stdin from child process.

#import('dart:io');

#source("process_test_util.dart");

main() {
  // Running dart without arguments makes it close right away.
  var future = Process.start(new Options().executable, []);
  future.then((process) {
    // Ignore error on stdin.
    process.stdin.onError = (e) => null;

    // Write to the stdin after the process is terminated to test
    // writing to a broken pipe.
    process.onExit = (code) {
      Expect.isFalse(process.stdin.write([0]));
      process.close();
    };
  });
}
