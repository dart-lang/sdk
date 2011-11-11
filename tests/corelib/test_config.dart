// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("corelib_test_config");

#import("../../tools/testing/dart/test_runner.dart");
#import("../../tools/testing/dart/status_file_parser.dart");

class CorelibTestSuite {
  String directoryPath = "tests/corelib/src";
  final String statusFilePath = "tests/corelib/corelib.status";
  Function doTest;
  Function doDone;
  String shellPath;
  String pathSeparator;
  Map configuration;
  TestExpectationsMap testExpectationsMap;

  CorelibTestSuite(Map this.configuration) {
    shellPath = getDartShellFileName(configuration) ;
    pathSeparator = new Platform().pathSeparator();
  }

  void forEachTest(Function onTest, [Function onDone = null]) {
    doTest = onTest;
    doDone = onDone;

    // Read test expectations from status file.
    testExpectationsMap = ReadTestExpectations(statusFilePath, configuration);

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
    if (!filename.endsWith("Test.dart")) return;

    Expect.isTrue(filename.contains(directoryPath));
    int start = filename.lastIndexOf(pathSeparator);
    String testName = filename.substring(start + 1, filename.length - 5);
    Set<String> expectations = testExpectationsMap.expectations(testName);

    // TODO(whesse): Skip files with internal directives, and multipart files,
    //               until they are handled correctly.
    if (expectations.contains(SKIP)) return;


    doTest(new TestCase(testName,
                        shellPath,
                        <String>["--enable_type_checks",
                                 "--ignore-unrecognized-flags",
                                 filename ],
                        completeHandler,
                        expectations));
  }
  
  void completeHandler(TestCase testCase) {
    TestOutput output = testCase.output;
    String expected = "";
    testCase.expectedOutcomes.forEach((value) { expected += value + " "; });
    print("");
    print(testCase.displayName);
    print("  Result:${output.result}  Expected:$expected");
    print("  Exit code: ${output.exitCode} Time: ${output.time}");
  }
}
