// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process working directory test.

library ProcessWorkingDirectoryTest;

import "package:expect/expect.dart";
import "dart:io";
import "process_test_util.dart";

class ProcessWorkingDirectoryTest {
  static String get fullTestFilePath {
    // Extract full path, since we run processes from another directory.
    File path = new File(getProcessTestFileName());
    Expect.isTrue(path.existsSync());
    return path.resolveSymbolicLinksSync();
  }

  static void testValidDirectory() {
    Directory directory =
        Directory.systemTemp.createTempSync('dart_process_working_directory');
    Expect.isTrue(directory.existsSync());

    Process
        .start(fullTestFilePath, const ["0", "0", "99", "0"],
            workingDirectory: directory.path)
        .then((process) {
      process.exitCode.then((int exitCode) {
        Expect.equals(exitCode, 99);
        directory.deleteSync();
      });
      process.stdout.listen((_) {});
      process.stderr.listen((_) {});
    }).catchError((error) {
      directory.deleteSync();
      Expect.fail("Couldn't start process");
    });
  }

  static void testInvalidDirectory() {
    Directory directory =
        Directory.systemTemp.createTempSync('dart_process_working_directory');
    Expect.isTrue(directory.existsSync());

    Process
        .start(fullTestFilePath, const ["0", "0", "99", "0"],
            workingDirectory: directory.path + "/subPath")
        .then((process) {
      Expect.fail("bad process completed");
      directory.deleteSync();
    }).catchError((e) {
      Expect.isNotNull(e);
      directory.deleteSync();
    });
  }
}

main() {
  ProcessWorkingDirectoryTest.testValidDirectory();
  ProcessWorkingDirectoryTest.testInvalidDirectory();
}
