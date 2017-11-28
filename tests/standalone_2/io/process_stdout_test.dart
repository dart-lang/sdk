// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to test process communication.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:io';
import 'dart:math';

import "process_test_util.dart";

void test(Future<Process> future, int expectedExitCode) {
  future.then((process) {
    process.exitCode.then((exitCode) {
      Expect.equals(expectedExitCode, exitCode);
    });

    List<int> input_data = "ABCDEFGHI\n".codeUnits;
    final int input_dataSize = input_data.length;

    int received = 0;
    List<int> buffer = [];

    void readData(List<int> data) {
      buffer.addAll(data);
      for (int i = received; i < min(data.length, buffer.length) - 1; i++) {
        Expect.equals(data[i], buffer[i]);
      }
      received = buffer.length;
      if (received >= input_dataSize) {
        // We expect an extra character on windows due to carriage return.
        if (13 == buffer[input_dataSize - 1] &&
            input_dataSize + 1 == received) {
          Expect.equals(13, buffer[input_dataSize - 1]);
          Expect.equals(10, buffer[input_dataSize]);
          buffer.removeLast();
        }
      }
    }

    process.stderr.listen((_) {});
    process.stdin.add(input_data);
    process.stdin.flush().then((_) => process.stdin.close());
    process.stdout.listen(readData);
  });
}

main() {
  // Run the test using the process_test binary.
  test(
      Process.start(getProcessTestFileName(), const ["0", "1", "99", "0"]), 99);

  // Run the test using the dart binary with an echo script.
  // The test runner can be run from either the root or from runtime.
  var scriptFile = new File("tests/standalone_2/io/process_std_io_script.dart");
  if (!scriptFile.existsSync()) {
    scriptFile =
        new File("../tests/standalone_2/io/process_std_io_script.dart");
  }
  Expect.isTrue(scriptFile.existsSync());
  test(Process.start(Platform.executable, [scriptFile.path, "0"]), 0);
}
