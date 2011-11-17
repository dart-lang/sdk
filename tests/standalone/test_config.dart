// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("standalone_test_config");

#import("../../tools/testing/dart/status_file_parser.dart");
#import("../../tools/testing/dart/test_config_utils.dart");
#import("../../tools/testing/dart/test_runner.dart");

class StandaloneTestSuite {
  String directoryPath = "tests/standalone/src";
  final String statusFilePath = "tests/standalone/standalone.status";
  Function doTest;
  Function doDone;
  String shellPath;
  String pathSeparator;
  Map configuration;
  TestExpectations testExpectations;

  StandaloneTestSuite(Map this.configuration) {
    shellPath = getDartShellFileName(configuration) ;
    pathSeparator = new Platform().pathSeparator();
  }

  void forEachTest(Function onTest, [Function onDone = null]) {
    doTest = onTest;
    doDone = (ignore) => onDone();

    // Read test expectations from status file.
    testExpectations = new TestExpectations();
    ReadTestExpectationsInto(testExpectations, statusFilePath, configuration);

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

    // If patterns are given only list the files that match one of the
    // patterns.
    var patterns = configuration['patterns'];
    if (!patterns.isEmpty() &&
        !patterns.some((re) => re.hasMatch(filename))) {
      return;
    }

    int start = filename.lastIndexOf(pathSeparator);
    String testName = filename.substring(start + 1, filename.length - 5);
    Set<String> expectations = testExpectations.expectations(testName);

    if (expectations.contains(SKIP)) return;

    var optionsFromFile = TestUtils.optionsFromFile(filename, configuration);
    var argumentLists =
        TestUtils.argumentLists(filename, optionsFromFile, configuration);
    for (var args in argumentLists) {
      var timeout = configuration['timeout'];
      var isNegative = optionsFromFile['isNegative'];
      doTest(new TestCase(testName,
                          shellPath,
                          args,
                          timeout,
                          completeHandler,
                          expectations,
                          isNegative));
    }
  }

  void completeHandler(TestCase testCase) {
  }
}
