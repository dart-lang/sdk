// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("standalone_test_config");

#import("../../tools/testing/dart/test_runner.dart");
#import("../../tools/testing/dart/status_file_parser.dart");

class StandaloneTestSuite {
  String directoryPath = "tests/standalone/src";
  final String statusFilePath = "tests/standalone/standalone.status";
  Function doTest;
  Function doDone;
  String shellPath;
  String pathSeparator;

  StandaloneTestSuite() {
    shellPath = getDartShellFileName() ;
    pathSeparator = new Platform().pathSeparator();
  }

  void forEachTest(Function onTest, [Function onDone = null]) {
    doTest = onTest;
    doDone = onDone;

    // Read configuration from status file.
    List<Section> sections = new List<Section>();
    ReadConfigurationInto(statusFilePath, sections);

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
    int start = filename.lastIndexOf(pathSeparator);
    String testName = filename.substring(start + 1, filename.length - 5);
    // TODO(whesse): Gather test case info from status file and test file.
    doTest(new TestCase(testName,
                        shellPath,
                        <String>["--enable_type_checks",
                                 "--ignore-unrecognized-flags",
                                 filename ],
                        completeHandler,
                        new Set.from([PASS, FAIL, CRASH, TIMEOUT])));
  }
  
  void completeHandler(TestCase testCase) {
    TestOutput output = testCase.output;
    print("Exit code: ${output.exitCode} Time: ${output.time}");
  }
}
