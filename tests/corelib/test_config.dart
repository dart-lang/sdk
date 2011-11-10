// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("corelib_test_config");

#import("../../tools/testing/dart/test_runner.dart");
#import("../../tools/testing/dart/status_file_parser.dart");

class CorelibTestSuite {
  String directoryPath = "tests/corelib/src";
  Function doTest;
  Function doDone;
  String shellPath;
  String pathSeparator;

  CorelibTestSuite() {
    shellPath = getDartShellFileName() ;
    pathSeparator = new Platform().pathSeparator();
  }

  void forEachTest(Function onTest, [Function onDone = null]) {
    doTest = onTest;
    doDone = onDone;
    processDirectory();
  }

  void processDirectory() {
    directoryPath = getDirname(directoryPath);
    Directory dir = new Directory(directoryPath);
    dir.errorHandler = (s) {
      throw s;
    };
    dir.fileHandler = processFile;
    dir.doneHandler = doDone;
    dir.list(false);
  }

  void processFile(String filename) {
    if (filename.endsWith("Test.dart")) {
      int start = filename.lastIndexOf(pathSeparator);
      String displayName = filename.substring(start + 1, filename.length - 5);
      // TODO(whesse): Gather test case info from status file and test file.
      doTest(new TestCase(displayName,
                          shellPath,
                          <String>["--enable_type_checks",
                                   "--ignore-unrecognized-flags",
                                   filename ],
                          completeHandler,
                          new Set.from([PASS, FAIL, CRASH, TIMEOUT])));
    }
  }
  
  void completeHandler(TestCase testCase) {
    TestOutput output = testCase.output;
    print("Exit code: ${output.exitCode} Time: ${output.time}");
  }
}
