// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("co19_test_config");

#import("../../tools/testing/dart/status_file_parser.dart");
#import("../../tools/testing/dart/test_config_utils.dart");
#import("../../tools/testing/dart/test_runner.dart");

class Co19TestSuite {
  String directoryPath = "tests/co19/src";
  Function doTest;
  Function doDone;
  String shellPath;
  String pathSeparator;
  Map configuration;
  TestExpectations testExpectations;
  RegExp testRegExp;

  Co19TestSuite(Map this.configuration) {
    shellPath = getDartShellFileName(configuration) ;
    pathSeparator = new Platform().pathSeparator();
    testRegExp = new RegExp(@"t[0-9]{2}.dart$");
  }

  void forEachTest(Function onTest, [Function onDone = null]) {
    doTest = onTest;
    doDone = (ignore) => onDone();

    // Read test expectations from status file.
    testExpectations = new TestExpectations(complexMatching: true);
    ReadTestExpectationsInto(testExpectations,
                             "tests/co19/co19-compiler.status",
                             configuration);
    ReadTestExpectationsInto(testExpectations,
                             "tests/co19/co19-frog.status",
                             configuration);
    ReadTestExpectationsInto(testExpectations,
                             "tests/co19/co19-runtime.status",
                             configuration);

    processDirectory(directoryPath);
  }

  void processDirectory(String path) {
    path = getDirname(path);
    Directory dir = new Directory(path);
    dir.errorHandler = (s) {
      throw s;
    };
    dir.fileHandler = processFile;
    dir.doneHandler = doDone;
    dir.list(recursive: true);
  }

  void processFile(String filename) {
    if (!testRegExp.hasMatch(filename)) return;

    // If patterns are given only list the files that match one of the
    // patterns.
    var patterns = configuration['patterns'];
    if (!patterns.isEmpty() &&
        !patterns.some((re) => re.hasMatch(filename))) {
      return;
    }

    int start = filename.lastIndexOf('src' + pathSeparator);
    String testName = filename.substring(start + 4, filename.length - 5);
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

  void completeHandler(TestCase test) {
  }
}
