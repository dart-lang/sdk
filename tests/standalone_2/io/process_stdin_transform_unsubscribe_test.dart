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

    process.stdout.listen((_) {});
    process.stderr.listen((_) {});
    process.stdin.writeln("Line1");
    process.stdin.flush().then((_) {
      print("flush completed");
    });
  });
}

main() {
  var scriptName = "process_stdin_transform_unsubscribe_script.dart";
  var scriptFile = new File("tests/standalone_2/io/$scriptName");
  if (!scriptFile.existsSync()) {
    scriptFile = new File("../tests/standalone_2/io/$scriptName");
  }
  Expect.isTrue(scriptFile.existsSync());
  test(Process.start(Platform.executable, [scriptFile.path]), 0);
}
