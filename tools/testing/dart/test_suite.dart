// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("test_suite");

#import("status_file_parser.dart");
#import("test_runner.dart");

interface TestSuite {
  void forEachTest(Function onTest, [Function onDone]);
}


class StandardTestSuite implements TestSuite {
  Map configuration;
  String directoryPath;
  List<String> statusFilePaths;
  Function doTest;
  Function doDone;
  String shellPath;
  TestExpectations testExpectations;

  StandardTestSuite(Map this.configuration,
                    String this.directoryPath,
                    List<String> this.statusFilePaths) {
    shellPath = getDartShellFileName(configuration) ;
  }


  void isTestFile(String filename) => filename.endsWith("Test.dart");

  void listRecursively() => false;

  void complexStatusMatching() => false;

  void forEachTest(Function onTest, [Function onDone = null]) {
    doTest = onTest;
    doDone = (ignore) => (onDone != null) ? onDone() : null;

    // Read test expectations from status files.
    testExpectations =
        new TestExpectations(complexMatching: complexStatusMatching());
    for (var statusFilePath in statusFilePaths) {
      ReadTestExpectationsInto(testExpectations,
                               statusFilePath,
                               configuration);
    }

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
    dir.list(recursive: listRecursively());
  }

  void processFile(String filename) {
    if (!isTestFile(filename)) return;

    // If patterns are given only list the files that match one of the
    // patterns.
    var patterns = configuration['patterns'];
    if (!patterns.isEmpty() &&
        !patterns.some((re) => re.hasMatch(filename))) {
      return;
    }

    int start = filename.lastIndexOf('src' + new Platform().pathSeparator());
    String testName = filename.substring(start + 4, filename.length - 5);
    Set<String> expectations = testExpectations.expectations(testName);

    if (expectations.contains(SKIP)) return;

    var optionsFromFile = optionsFromFile(filename);
    var argumentLists = argumentLists(filename, optionsFromFile);
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

  List<List<String>> argumentLists(String filename, Map optionsFromFile) {
    List args = ["--ignore-unrecognized-flags"];
    if (configuration["checked"]) {
      args.add("--enable_type_checks");
    }
    if (configuration["component"] == "leg") {
      args.add("--enable_leg");
    }
    if (configuration["component"] == "dartc") {
      if (configuration["mode"] == "release") {
        args.add("--optimize");
      }
    }

    List<String> dartOptions = optionsFromFile["dartOptions"];
    args.addAll(dartOptions == null ? [filename] : dartOptions);

    var result = new List<List<String>>();
    List<List<String>> vmOptionsList = optionsFromFile["vmOptions"];
    if (vmOptionsList.isEmpty()) {
      result.add(args);
    } else {
      for (var vmOptions in vmOptionsList) {
        vmOptions.addAll(args);
        result.add(vmOptions);
      }
    }

    return result;
  }

  Map optionsFromFile(String filename) {
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

    if (contents.contains("@compile-error") ||
        contents.contains("@runtime-error")) {
      isNegative = true;
    } else if (contents.contains("@dynamic-type-error") &&
               configuration['checked']) {
      isNegative = true;
    }

    return { "vmOptions": result,
             "dartOptions": dartOptions,
             "isNegative" : isNegative };
  }
}
