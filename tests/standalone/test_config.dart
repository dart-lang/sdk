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

    List args = ["--ignore-unrecognized-flags"];
    if (configuration["checked"]) {
      args.add("--enable_type_checks");
    }
    if (configuration["component"] == "leg") {
      args.add("--enable_leg");
    }

    var optionsFromFile = testOptions(filename);
    List<List<String>> optionsList = optionsFromFile["vmOptions"];
    List<String> dartOptions = optionsFromFile["dartOptions"];
    args.addAll(dartOptions == null ? [filename] : dartOptions);

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

  Map testOptions(String filename) {
    // Since '.*' does not match a newline these RegExps can be used
    // on the entire contents of files instead of individual lines.
    RegExp testOptionsRegExp = const RegExp(@"// VMOptions=(.*)");
    RegExp dartOptionsRegExp = const RegExp(@"// DartOptions=(.*)");

    // Read the entire file into a byte buffer and transform it to a
    // String. This will treat the file as ascii but the only parts
    // we are interested in will be ascii in any case.
    File file = new File(filename);
    file.openSync();
    List chars = new List(file.lengthSync());
    var offset = 0;
    while (offset != chars.length) {
      offset += file.readListSync(chars, offset, chars.length - offset);
    }
    file.closeSync();
    String contents = new String.fromCharCodes(chars);
    chars = null;

    // Find the options in the file.
    List<List> result = new List<List>();
    List<String> dartOptions;
    bool isNegative = false;

    Iterable<Match> matches = testOptionsRegExp.allMatches(contents);
    for (var match in matches) {
      result.add(match[1].split(' ').filter((e) => e != ''));
    }

    matches = dartOptionsRegExp.allMatches(contents);
    for (var match in matches) {
      if (dartOptions != null) {
        throw new Exception(
            'More than one "// DartOptions=" line in test $filename');
      }
      dartOptions = match[1].split(' ').filter((e) => e != '');
    }

    return { "vmOptions": result, "dartOptions": dartOptions };
  }
  
  void completeHandler(TestCase testCase) {
  }
}
