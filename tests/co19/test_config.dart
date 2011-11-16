// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("co19_test_config");

#import("../../tools/testing/dart/test_runner.dart");
#import("../../tools/testing/dart/status_file_parser.dart");

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
    var isNegative = optionsFromFile["isNegative"];

    if (optionsList.isEmpty()) {
      doTest(new TestCase(testName,
                          shellPath,
                          args,
                          configuration["timeout"],
                          completeHandler,
                          expectations,
                          isNegative));
    } else {
      for (var options in optionsList) {
        options.addAll(args);
        doTest(new TestCase(testName,
                            shellPath,
                            options,
                            configuration["timeout"],
                            completeHandler,
                            expectations,
                            isNegative));
      }
    }
  }


  Map testOptions(String filename) {
    RegExp testOptionsRegExp = const RegExp(@"// VMOptions=(.*)");
    RegExp dartOptionsRegExp = const RegExp(@"// DartOptions=(.*)");
    File file = new File(filename);
    FileInputStream fileStream = file.openInputStream();
    StringInputStream lines = new StringInputStream(fileStream);

    List<List> result = new List<List>();
    List<String> dartOptions;
    bool isNegative = false;
    String line;
    while ((line = lines.readLine()) != null) {
      Match match = testOptionsRegExp.firstMatch(line);
      if (match != null) {
        result.add(match[1].split(' ').filter((e) => e != ''));
      }

      match = dartOptionsRegExp.firstMatch(line);
      if (match != null) {
        if (dartOptions != null) {
          throw new Exception(
              'More than one "// DartOptions=" line in test $filename');
        }
        dartOptions = match[1].split(' ').filter((e) => e != '');
      }

      if (line.contains("@compile-error") || line.contains("@runtime-error")) {
        isNegative = true;
      } else if (line.contains("@dynamic-type-error") &&
                 configuration['checked']) {
        isNegative = true;
      }
    }
    return { "vmOptions": result,
             "dartOptions": dartOptions,
             "isNegative" : isNegative };
  }

  void completeHandler(TestCase testCase) {
  }
}
