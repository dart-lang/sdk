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
    doDone = (ignore) => onDone();

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

    // If patterns are given only list the files that match one of the
    // patterns.
    var patterns = configuration['patterns'];
    if (!patterns.isEmpty() &&
        !patterns.some((re) => re.hasMatch(filename))) {
      return;
    }

    int start = filename.lastIndexOf(pathSeparator);
    String testName = filename.substring(start + 1, filename.length - 5);
    Set<String> expectations = testExpectationsMap.expectations(testName);

    // TODO(whesse): Skip files with internal directives, and multipart files,
    //               until they are handled correctly.
    if (expectations.contains(SKIP)) return;

    List args = ["--ignore-unrecognized-flags"];
    if (configuration["checked"]) {
      args.add("--enable_type_checks");
    }
    if (configuration["component"] == "leg") {
      args.add("--enable_leg");
    }
    args.add(filename);

    List<List> optionsList = testOptions(filename);
    if (optionsList.isEmpty()) {
      doTest(new TestCase(testName,
                          shellPath,
                          args,
                          configuration["timeout"],
                          completeHandler,
                          expectations));
    } else {
      for (var options in optionsList) {
        options.addAll(args);
        doTest(new TestCase(testName,
                            shellPath,
                            options,
                            configuration["timeout"],
                            completeHandler,
                            expectations));
      }        
    }
  }

  List<List> testOptions(String filename) {
    RegExp testOptionsRegExp = const RegExp(@"// VMOptions=(.*)");
    File file = new File(filename);
    FileInputStream fileStream = file.openInputStream();
    StringInputStream lines = new StringInputStream(fileStream);

    List<List> result = new List<List>();
    String line;
    while ((line = lines.readLine()) != null) {
      Match match = testOptionsRegExp.firstMatch(line);
      if (match != null) {
        result.add(match[1].split(' ').filter((e) => e != ''));
      }
    }
    return result;
  }
  
  void completeHandler(TestCase testCase) {
  }
}
