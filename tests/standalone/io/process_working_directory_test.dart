// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process working directory test.

#library("ProcessWorkingDirectoryTest");
#import("dart:io");
#source("process_test_util.dart");

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
    Process process = Process.start(fullTestFilePath,
                                    const ["0", "0", "99", "0"],
                                    options);

    process.onExit = (int exitCode) {
      Expect.equals(exitCode, 99);
      process.close();
      directory.deleteSync();
    };

    process.onError = (error) {
      Expect.fail("error running process $error");
      directory.deleteSync();
    };
  }

  static void testInvalidDirectory() {
    Directory directory = new Directory("").createTempSync();
    Expect.isTrue(directory.existsSync());

    var options = new ProcessOptions();
    options.workingDirectory = directory.path.concat("/subPath");
    Process process = Process.start(fullTestFilePath,
                                    const ["0", "0", "99", "0"],
                                    options);

    process.onExit = (int exitCode) {
      Expect.fail("bad process completed");
      process.close();
      directory.deleteSync();
    };

    process.onError = (error) {
      Expect.isNotNull(error);
      directory.deleteSync();
    };
  }
}



main() {
  ProcessWorkingDirectoryTest.testValidDirectory();
  ProcessWorkingDirectoryTest.testInvalidDirectory();
}
