// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to test closed stdin from child process.

#source("ProcessTestUtil.dart");

main() {
  // Running dart without arguments makes it close right away.
  Process process = new Process(getDartBinFileName(), []);

  // Write to the stdin after the process is terminated to test
  // writing to a broken pipe.
  OutputStream output = process.stdin;
  process.exitHandler = (code) {
    Expect.isFalse(output.write([0]));
    process.close();
  };

  process.start();
}
