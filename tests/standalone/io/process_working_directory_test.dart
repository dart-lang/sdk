// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process working directory test.

library ProcessWorkingDirectoryTest;
import "dart:io";
import "process_test_util.dart";

class ProcessWorkingDirectoryTest {
  static String get fullTestFilePath {
    // Extract full path, since we run processes from another directory.
    File path = new File(getProcessTestFileName());
    Expect.isTrue(path.existsSync());
    return path.fullPathSync();
  }

  static void testValidDirectory() {
    Directory directory = new Directory("").createTempSync();
    Expect.isTrue(directory.existsSync());

    var options = new ProcessOptions();
    options.workingDirectory = directory.path;
    var processFuture =
        Process.start(fullTestFilePath, const ["0", "0", "99", "0"], options);
    processFuture.then((process) {
      process.onExit = (int exitCode) {
        Expect.equals(exitCode, 99);
        directory.deleteSync();
      };
      process.stdout.onData = process.stdout.read;
      process.stderr.onData = process.stderr.read;
    }).catchError((error) {
      directory.deleteSync();
      Expect.fail("Couldn't start process");
    });
  }

  static void testInvalidDirectory() {
    Directory directory = new Directory("").createTempSync();
    Expect.isTrue(directory.existsSync());

    var options = new ProcessOptions();
    options.workingDirectory = directory.path.concat("/subPath");
    var future = Process.start(fullTestFilePath,
                               const ["0", "0", "99", "0"],
                               options);
    future.then((process) {
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
