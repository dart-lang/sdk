// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("test_suite");

#import("status_file_parser.dart");
#import("test_runner.dart");
#import("multitest.dart");


interface TestSuite {
  void forEachTest(Function onTest, [Function onDone]);
}


class CCTestListerIsolate extends Isolate {
  CCTestListerIsolate() : super.heavy();

  void main() {
    port.receive((String runnerPath, SendPort replyTo) {
      var p = new Process(runnerPath, ["--list"]);
      StringInputStream stdoutStream = new StringInputStream(p.stdout);
      List<String> tests = new List<String>();
      stdoutStream.dataHandler = () {
        String line = stdoutStream.readLine();
        while (line != null) {
          tests.add(line);
          line = stdoutStream.readLine();
        }
      };
      p.exitHandler = (code) {
        if (code < 0) {
          print("Failed to list tests: $runnerPath --list");
          replyTo.send("");
        }
        for (String test in tests) {
          replyTo.send(test);
        }
        replyTo.send("");
      };
      p.start();
    });
  }
}


class CCTestSuite implements TestSuite {
  Map configuration;
  String suiteName;
  String runnerPath;
  List<String> statusFilePaths;
  Function doTest;
  Function doDone;
  ReceivePort receiveTestName;
  TestExpectations testExpectations;

  CCTestSuite(Map this.configuration,
              String this.suiteName,
              String runnerName,
              List<String> this.statusFilePaths) {
    runnerPath = TestUtils.buildDir(configuration) + runnerName;
  }

  void complexStatusMatching() => false;

  void testNameHandler(String testName, ignore) {
    if (testName == "") {
      receiveTestName.close();
      doDone(true);
    } else {
      // If patterns are given only list the files that match one of the
      // patterns. Use the name "suiteName/testName" for cc tests.
      var patterns = configuration['patterns'];
      if (!patterns.isEmpty()) {
        var constructedName = '$suiteName/$testName';
        if (!patterns.some((re) => re.hasMatch(constructedName))) return;
      }

      var expectations = testExpectations.expectations(testName);

      if (expectations.contains(SKIP)) return;

      // The cc test runner takes options after the name of the test
      // to run.
      var args = [testName];
      args.addAll(TestUtils.standardOptions(configuration));
      var timeout = configuration['timeout'];

      doTest(new TestCase(testName,
                          runnerPath,
                          args,
                          timeout,
                          completeHandler,
                          expectations));

      receiveTestName.receive(testNameHandler);
    }
  }

  void forEachTest(Function onTest, [Function onDone]) {
    doTest = onTest;
    doDone = (ignore) => (onDone != null) ? onDone() : null;

    testExpectations =
        new TestExpectations(complexMatching: complexStatusMatching());
    for (var statusFilePath in statusFilePaths) {
      ReadTestExpectationsInto(testExpectations,
                               statusFilePath,
                               configuration);
    }

    receiveTestName = new ReceivePort();
    new CCTestListerIsolate().spawn().then((port) {
        port.send(runnerPath, receiveTestName.toSendPort());
        receiveTestName.receive(testNameHandler);
    });
  }

  void completeHandler(TestCase testCase) {
  }
}


class StandardTestSuite implements TestSuite {
  Map configuration;
  String directoryPath;
  List<String> statusFilePaths;
  Function doTest;
  Function doDone;
  int activeMultitests = 0;
  bool listingDone = false;
  String shellPath;
  TestExpectations testExpectations;

  StandardTestSuite(Map this.configuration,
                    String this.directoryPath,
                    List<String> this.statusFilePaths) {
    shellPath = TestUtils.dartShellFileName(configuration) ;
  }


  void isTestFile(String filename) => filename.endsWith("Test.dart");

  void listRecursively() => false;

  void complexStatusMatching() => false;

  List<String> additionalOptions() => [];

  void forEachTest(Function onTest, [Function onDone = null]) {
    doTest = onTest;
    doDone = (onDone != null) ? onDone : (() => null);

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
    dir.doneHandler = directoryListingDone;
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


    var timeout = configuration['timeout'];
    var optionsFromFile = optionsFromFile(filename);

    Function createTestCase(String filename,
                            bool isNegative,
                            [bool isNegativeIfChecked = false]) {
      // Look up expectations in status files using a modified file path.
      String pathSeparator = new Platform().pathSeparator();
      String testName;
      int start = filename.lastIndexOf('src' + pathSeparator);
      if (start != -1) {
        testName = filename.substring(start + 4, filename.length - 5);
      } else {
        // Only multitests in a temporary directory should reach here.
        start = filename.lastIndexOf(pathSeparator);
        int middle = filename.lastIndexOf('_');
        testName = filename.substring(start + 1, middle) + pathSeparator +
            filename.substring(middle + 1, filename.length - 5);
      }
      Set<String> expectations = testExpectations.expectations(testName);

      if (expectations.contains(SKIP)) return;

      isNegative = isNegative ||
          (configuration['checked'] && isNegativeIfChecked);
      var argumentLists = argumentListsFromFile(filename, optionsFromFile);
      for (var args in argumentLists) {
        doTest(new TestCase(testName,
                            shellPath,
                            args,
                            timeout,
                            completeHandler,
                            expectations,
                            isNegative));
      }
    }


    if (optionsFromFile['isMultitest']) {
      ++activeMultitests;
      DoMultitest(filename,
                  TestUtils.buildDir(configuration),
                  directoryPath,
                  createTestCase,
                  multitestDone);
    } else {
      createTestCase(filename, optionsFromFile['isNegative']);
    }
  }

  void multitestDone() {
    --activeMultitests;
    if (activeMultitests == 0 && listingDone) {
      doDone();
    }
  }

  void directoryListingDone(ignore) {
    listingDone = true;
    if (activeMultitests == 0) {
      doDone();
    }
  }

  void completeHandler(TestCase testCase) {
  }

  List<List<String>> argumentListsFromFile(String filename,
                                           Map optionsFromFile) {
    List args = TestUtils.standardOptions(configuration);
    args.addAll(additionalOptions());

    bool isMultitest = optionsFromFile["isMultitest"];
    List<String> dartOptions = optionsFromFile["dartOptions"];
    List<List<String>> vmOptionsList = optionsFromFile["vmOptions"];
    Expect.isTrue(!isMultitest || dartOptions == null);
    args.addAll(dartOptions == null ? [filename] : dartOptions);

    var result = new List<List<String>>();
    Expect.isFalse(vmOptionsList.isEmpty(), "empty vmOptionsList");
    for (var vmOptions in vmOptionsList) {
      if (isMultitest) {
        // Make copy of vmOptions, since we will modify it at each iteration.
        vmOptions = new List<String>.from(vmOptions);
      }
      vmOptions.addAll(args);
      result.add(vmOptions);
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
    if (result.isEmpty()) result.add([]);

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

    bool isMultitest = contents.contains("///");

    return { "vmOptions": result,
             "dartOptions": dartOptions,
             "isNegative": isNegative,
             "isMultitest": isMultitest};
  }
}


class TestUtils {
  static String executableName(Map configuration) {
    String postfix =
        (new Platform().operatingSystem() == 'windows') ? '.exe' : '';
    switch (configuration['component']) {
      case 'vm':
        return 'dart$postfix';
      case 'dartc':
        return 'compiler/bin/dartc_test$postfix';
      case 'frog':
      case 'leg':
          return 'frog/bin/frog$postfix';
      case 'frogsh':
        return 'frog/bin/frogsh$postfix';
      default:
        throw "Unknown executable for: ${configuration['component']}";
    }
  }


  static String dartShellFileName(Map configuration) {
    var name = buildDir(configuration) + executableName(configuration);
    if (!(new File(name)).existsSync()) {
      throw "Executable '$name' does not exist";
    }
    return name;
  }

  static String buildDir(Map configuration) {
    var buildDir = '';
    var system = configuration['system'];
    if (system == 'linux') {
      buildDir = 'out/';
    } else if (system == 'macos') {
      buildDir = 'xcodebuild/';
    }
    buildDir += (configuration['mode'] == 'debug') ? 'Debug_' : 'Release_';
    buildDir += configuration['architecture'] + '/';
    return buildDir;
  }

  static List<String> standardOptions(Map configuration) {
    List args = ["--ignore-unrecognized-flags"];
    if (configuration["checked"]) {
      args.add('--enable_asserts');
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
    return args;
  }
}
