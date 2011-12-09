// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("test_suite");

#import("status_file_parser.dart");
#import("test_runner.dart");
#import("multitest.dart");

#source("browser_test.dart");

interface TestSuite {
  void forEachTest(Function onTest, Map testCache, [Function onDone]);
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
      // Only run the tests that match the pattern. Use the name
      // "suiteName/testName" for cc tests.
      RegExp pattern = configuration['selectors'][suiteName];
      String constructedName = '$suiteName/$testName';
      if (!pattern.hasMatch(constructedName)) return;

      var expectations = testExpectations.expectations(testName);

      if (configuration["report"]) {
        SummaryReport.add(expectations);
      }

      if (expectations.contains(SKIP)) return;

      // The cc test runner takes options after the name of the test
      // to run.
      var args = [testName];
      args.addAll(TestUtils.standardOptions(configuration));

      doTest(new TestCase('$suiteName/$testName',
                          runnerPath,
                          args,
                          configuration,
                          completeHandler,
                          expectations));

      receiveTestName.receive(testNameHandler);
    }
  }

  void forEachTest(Function onTest, Map testCache, [Function onDone]) {
    doTest = onTest;
    doDone = (ignore) => (onDone != null) ? onDone() : null;

    var filesRead = 0;
    void statusFileRead() {
      filesRead++;
      if (filesRead == statusFilePaths.length) {
        receiveTestName = new ReceivePort();
        new CCTestListerIsolate().spawn().then((port) {
            port.send(runnerPath, receiveTestName.toSendPort());
            receiveTestName.receive(testNameHandler);
        });
      }
    }

    testExpectations =
        new TestExpectations(complexMatching: complexStatusMatching());
    for (var statusFilePath in statusFilePaths) {
      ReadTestExpectationsInto(testExpectations,
                               statusFilePath,
                               configuration,
                               statusFileRead);
    }
  }

  void completeHandler(TestCase testCase) {
  }
}


class TestInformation {
  String filename;
  Map optionsFromFile;
  bool isNegative;
  bool isNegativeIfChecked;
  bool hasFatalTypeErrors;

  TestInformation(this.filename, this.optionsFromFile, this.isNegative,
                  this.isNegativeIfChecked, this.hasFatalTypeErrors);
}


class StandardTestSuite implements TestSuite {
  Map configuration;
  String suiteName;
  String directoryPath;
  List<String> statusFilePaths;
  Function doTest;
  Function doDone;
  int activeTestGenerators = 0;
  bool listingDone = false;
  TestExpectations testExpectations;
  List<TestInformation> cachedTests;
  final String pathSeparator;

  StandardTestSuite(Map this.configuration,
                    String this.suiteName,
                    String this.directoryPath,
                    List<String> this.statusFilePaths)
    : pathSeparator = new Platform().pathSeparator();

  void isTestFile(String filename) => filename.endsWith("Test.dart");

  void listRecursively() => false;

  void complexStatusMatching() => false;

  String shellPath() => TestUtils.dartShellFileName(configuration);

  List<String> additionalOptions() => [];

  void forEachTest(Function onTest, Map testCache, [Function onDone = null]) {
    doTest = onTest;
    doDone = (onDone != null) ? onDone : (() => null);

    var filesRead = 0;
    void statusFileRead() {
      filesRead++;
      if (filesRead == statusFilePaths.length) {
        // Checked if we have already found and generated the tests for
        // this suite.
        if (!testCache.containsKey(suiteName)) {
          cachedTests = testCache[suiteName] = [];
          processDirectory();
        } else {
          // We rely on enqueueing completing asynchronously so use a
          // timer to make it so.
          void enqueueCachedTests(Timer ignore) {
            for (var info in testCache[suiteName]) {
              enqueueTestCaseFromTestInformation(info);
            }
            doDone();
          }
          new Timer(enqueueCachedTests, 0, false);
        }
      }
    }

    // Read test expectations from status files.
    testExpectations =
        new TestExpectations(complexMatching: complexStatusMatching());
    for (var statusFilePath in statusFilePaths) {
      ReadTestExpectationsInto(testExpectations,
                               statusFilePath,
                               configuration,
                               statusFileRead);
    }
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

  void enqueueTestCaseFromTestInformation(TestInformation info) {
    var filename = info.filename;
    var optionsFromFile = info.optionsFromFile;
    var isNegative = info.isNegative;

    // Look up expectations in status files using a modified file path.
    String testName;
    int start = filename.lastIndexOf('src' + pathSeparator);
    if (start != -1) {
      testName = filename.substring(start + 4, filename.length - 5);
    } else if (optionsFromFile['isMultitest']) {
      start = filename.lastIndexOf(pathSeparator);
      int middle = filename.lastIndexOf('_');
      testName = filename.substring(start + 1, middle) + pathSeparator +
          filename.substring(middle + 1, filename.length - 5);
    } else {
      // This case is hit by the dartc client compilation
      // tests. These tests are pretty broken compared to the
      // rest. They use the .dart suffix in the status files. They
      // find tests in weird ways (testing that they contain "#").
      // They need to be redone.
      start = filename.indexOf(directoryPath);
      testName = filename.substring(start + directoryPath.length + 1,
                                    filename.length);
    }
    Set<String> expectations = testExpectations.expectations(testName);
    if (configuration["report"]) {
      // Tests with multiple VMOptions are counted more than once.
      for (var dummy in optionsFromFile["vmOptions"]) {
        SummaryReport.add(expectations);
      }
    }
    if (expectations.contains(SKIP)) return;

    if (configuration['component'] == 'dartium') {
      enqueueDartiumTest(filename, testName, optionsFromFile,
                         expectations, isNegative);
      return;
    }
    // Only dartc supports fatal type errors. Enable fatal type
    // errors with a flag and treat tests that have fatal type
    // errors as negative.
    var enableFatalTypeErrors =
        (info.hasFatalTypeErrors && configuration['component'] == 'dartc');
    var argumentLists = argumentListsFromFile(filename,
                                              optionsFromFile,
                                              enableFatalTypeErrors);
    isNegative = isNegative ||
        (configuration['checked'] && info.isNegativeIfChecked) ||
        enableFatalTypeErrors;

    for (var args in argumentLists) {
      doTest(new TestCase('$suiteName/$testName',
                          shellPath(),
                          args,
                          configuration,
                          completeHandler,
                          expectations,
                          isNegative));
    }
  }

  Function makeTestCaseCreator(Map optionsFromFile) {
    return (String filename,
            bool isNegative,
            [bool isNegativeIfChecked = false,
             bool hasFatalTypeErrors = false]) {
      // Cache the test information for each test case.
      var info = new TestInformation(filename,
                                     optionsFromFile,
                                     isNegative,
                                     isNegativeIfChecked,
                                     hasFatalTypeErrors);
      cachedTests.add(info);
      enqueueTestCaseFromTestInformation(info);
    };
  }

  void processFile(String filename) {
    if (!isTestFile(filename)) return;

    // Only run the tests that match the pattern.
    RegExp pattern = configuration['selectors'][suiteName];
    if (!pattern.hasMatch(filename)) return;

    var optionsFromFile = optionsFromFile(filename);
    Function createTestCase = makeTestCaseCreator(optionsFromFile);

    if (optionsFromFile['isMultitest']) {
      testGeneratorStarted();
      DoMultitest(filename,
                  TestUtils.outputDir(configuration),
                  directoryPath,
                  createTestCase,
                  testGeneratorDone);
    } else {
      createTestCase(filename, optionsFromFile['isNegative']);
    }
  }

  void enqueueDartiumTest(String filename,
                          String testName,
                          Map optionsFromFile,
                          Set<String> expectations,
                          bool isNegative) {
    if (optionsFromFile['isMultitest']) return;
    bool isWebTest = optionsFromFile['containsDomImport'];
    bool isLibraryDefinition = optionsFromFile['isLibraryDefinition'];
    if (!isLibraryDefinition && optionsFromFile['containsSourceOrImport']) {
      print('Warning for $filename: Browser tests require #library ' +
            'in any file that uses #import or #source');
    }      

    Directory tempDir = new Directory((isWebTest ? 'client/' : '') +
                                      TestUtils.buildDir(configuration) +
                                      'tmp');
    // TODO(whesse): When implementing client web tests,
    // create directory in the client case, if it doesn't exist.
    tempDir.createTempSync();

    String dartTestFilename = new File(filename).fullPathSync();
    String dartWrapperFilename = '${tempDir.path}/test.dart';
    if (!isWebTest) {
      // test.dart will import the dart test directly, if it is a library,
      // or indirectly through test_as_library.dart, if it is not.
      String dartLibraryFilename;
      if (isLibraryDefinition) {
        dartLibraryFilename = dartTestFilename;
      } else {
        dartLibraryFilename = 'test_as_library.dart';
        File file = new File('${tempDir.path}/$dartLibraryFilename');
        RandomAccessFile dartLibrary = file.openSync(writable: true);
        dartLibrary.writeStringSync(WrapDartTestInLibrary(dartTestFilename));
        dartLibrary.closeSync();
      }  
      
      File file = new File(dartWrapperFilename);
      RandomAccessFile dartWrapper = file.openSync(writable: true);
      dartWrapper.writeStringSync(dartTestWrapper(dartLibraryFilename));
      dartWrapper.closeSync();
    } else {
      return;  // TODO(whesse): Implement client web tests on dartium.
    }
    // Create the HTML file for the test.
    File htmlTestBase = new File('${tempDir.path}/${getHtmlName(filename)}');
    RandomAccessFile htmlTest = htmlTestBase.openSync(writable: true);
    htmlTest.writeStringSync(GetHtmlContents(
        filename,
        'client/testing/unittest/test_controller.js',
        scriptType,
        dartWrapperFilename));
    htmlTest.closeSync();

    for (var vmOptions in optionsFromFile["vmOptions"]) {
      var drtFlags = ['-no-timeout'];
      var dartFlags = ['--enable_asserts', '--enable_type_checks'];
      dartFlags.addAll(vmOptions);
      drtFlags.add('--dart-flags=${Strings.join(dartFlags, " ")}');
      var args = drtFlags;
      args.add(htmlTestBase.fullPathSync());

      // Create BrowserTestCase and queue it.
      var testCase = new BrowserTestCase(
          testName,
          '/bin/echo',
          ['No compilation step for component dartium.'],
          dumpRenderTreeFilename,
          args,
          configuration,
          completeHandler,
          expectations, optionsFromFile['isNegative']);
      doTest(testCase);
    }        
  }

  static String dartTestWrapper(String library) {
    return DartTestWrapper('', '', 'dart:dom',
                           '../../../tests/isolate/src/TestFramework.dart',
                           library);
  }

  static String get scriptType() => 'application/dart';

  String getHtmlName(String filename) {
    return filename.replaceAll(pathSeparator, '_') + 'dartium.html';
  }

  static String get dumpRenderTreeFilename() {
    if (new Platform().operatingSystem() == 'macos') {
      return 'client/tests/drt/.app/Contents/MacOS/DumpRenderTree';
    } 
    return 'client/tests/drt/DumpRenderTree';
  }


  void testGeneratorStarted() {
    ++activeTestGenerators;
  }

  void testGeneratorDone() {
    --activeTestGenerators;
    if (activeTestGenerators == 0 && listingDone) {
      doDone();
    }
  }

  void directoryListingDone(ignore) {
    listingDone = true;
    if (activeTestGenerators == 0) {
      doDone();
    }
  }

  void completeHandler(TestCase testCase) {
  }

  List<List<String>> argumentListsFromFile(String filename,
                                           Map optionsFromFile,
                                           bool enableFatalTypeErrors) {
    List args = TestUtils.standardOptions(configuration);
    args.addAll(additionalOptions());
    if (enableFatalTypeErrors && configuration['component'] == 'dartc') {
      args.add('--fatal-type-errors');
    }

    bool isMultitest = optionsFromFile["isMultitest"];
    List<String> dartOptions = optionsFromFile["dartOptions"];
    List<List<String>> vmOptionsList = optionsFromFile["vmOptions"];
    Expect.isTrue(!isMultitest || dartOptions == null);
    if (dartOptions == null) {
      args.add(filename);
    } else {
      var filename = dartOptions[0];
      // TODO(ager): Get rid of this hack when the runtime checkout goes away.
      var file = new File(filename);
      if (!file.existsSync()) {
        filename = '../$filename';
        Expect.isTrue(new File(filename).existsSync());
        dartOptions[0] = filename;
      }
      args.addAll(dartOptions);
    }

    var result = new List<List<String>>();
    Expect.isFalse(vmOptionsList.isEmpty(), "empty vmOptionsList");
    for (var vmOptions in vmOptionsList) {
      var options = new List<String>.from(vmOptions);
      options.addAll(args);
      result.add(options);
    }

    return result;
  }

  Map optionsFromFile(String filename) {
    RegExp testOptionsRegExp = const RegExp(@"// VMOptions=(.*)");
    RegExp dartOptionsRegExp = const RegExp(@"// DartOptions=(.*)");
    RegExp multiTestRegExp = const RegExp(@"/// [0-9][0-9]:(.*)");
    RegExp leadingHashRegExp = const RegExp(@"^#", multiLine: true);
    RegExp isolateStubsRegExp = const RegExp(@"// IsolateStubs=(.*)");
    RegExp domImportRegExp =
        const RegExp(@"^#import.*(dart:(dom|html)|html\.dart).*\)",
                     multiLine: true);
    RegExp libraryDefinitionRegExp =
        const RegExp(@"^#library\(", multiLine: true);
    RegExp sourceOrImportRegExp =
        const RegExp(@"^#(source|import)\(", multiLine: true);
    
    // Read the entire file into a byte buffer and transform it to a
    // String. This will treat the file as ascii but the only parts
    // we are interested in will be ascii in any case.
    RandomAccessFile file = new File(filename).openSync();
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

    bool isMultitest = multiTestRegExp.hasMatch(contents);
    bool containsLeadingHash = leadingHashRegExp.hasMatch(contents);
    Match isolateMatch = isolateStubsRegExp.firstMatch(contents);
    String isolateStubs = isolateMatch != null ? isolateMatch[1] : '';
    bool containsDomImport = domImportRegExp.hasMatch(contents);
    bool isLibraryDefinition = libraryDefinitionRegExp.hasMatch(contents);
    bool containsSourceOrImport = sourceOrImportRegExp.hasMatch(contents);


    return { "vmOptions": result,
             "dartOptions": dartOptions,
             "isNegative": isNegative,
             "isMultitest": isMultitest,
             "containsLeadingHash" : containsLeadingHash,
             "isolateStubs" : isolateStubs,
             "containsDomImport": containsDomImport,
             "isLibraryDefinition": isLibraryDefinition,
             "containsSourceOrImport": containsSourceOrImport };
  }
}


class DartcCompilationTestSuite extends StandardTestSuite {
  List<String> _testDirs;
  int activityCount = 0;

  DartcCompilationTestSuite(Map configuration,
                            String suiteName,
                            String directoryPath,
                            List<String> this._testDirs,
                            List<String> expectations)
      : super(configuration,
              suiteName,
              directoryPath,
              expectations);

  void activityStarted() => ++activityCount;

  void activityCompleted() {
    if (--activityCount == 0) {
      directoryListingDone(true);
    }
  }

  String shellPath() => TestUtils.dartcCompilationShellPath(configuration);

  List<String> additionalOptions() {
    // TODO(ager): potentially register cleanup action to delete the temporary
    // directories?
    var tempDir = new Directory('');
    tempDir.createTempSync();
    return ['-check-only', '-fatal-type-errors', '-Werror', '-out', tempDir.path];
  }

  void processDirectory() {
    directoryPath = getDirname(directoryPath);
    // Enqueueing the directory listers is an activity.
    activityStarted();
    for (String testDir in _testDirs) {
      Directory dir = new Directory("$directoryPath/$testDir");
      if (dir.existsSync()) {
        activityStarted();
        dir.errorHandler = (s) {
          throw s;
        };
        dir.fileHandler = processFile;
        dir.doneHandler = (ignore) => activityCompleted();
        dir.list(recursive: listRecursively());
      }
    }
    // Completed the enqueueing of listers.
    activityCompleted();
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

  static String dartcCompilationShellPath(Map configuration) {
    var name = buildDir(configuration) + 'compiler/bin/dartc';
    if (!(new File(name)).existsSync()) {
      throw "Executable '$name' does not exist";
    }
    return name;
  }

  static String outputDir(Map configuration) {
    var outputDir = '';
    var system = configuration['system'];
    if (system == 'linux') {
      outputDir = 'out/';
    } else if (system == 'macos') {
      outputDir = 'xcodebuild/';
    }
    return outputDir;
  }

  static String buildDir(Map configuration) {
    var buildDir = outputDir(configuration);
    buildDir += (configuration['mode'] == 'debug') ? 'Debug_' : 'Release_';
    buildDir += configuration['arch'] + '/';
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

class SummaryReport {
  static int total = 0;
  static int skipped = 0;
  static int noCrash = 0;
  static int pass = 0;
  static int failOk = 0;
  static int fail = 0;
  static int crash = 0;
  static int timeout = 0;

  static void add(Set<String> expectations) {
    ++total;
    if (expectations.contains(SKIP)) {
      ++skipped;
    } else {
      if (expectations.contains(PASS) && expectations.contains(FAIL) &&
          !expectations.contains(CRASH) && !expectations.contains(OK)) {
        ++noCrash;
      }
      if (expectations.contains(PASS) && expectations.length == 1) {
        ++pass;
      }
      if (expectations.containsAll([FAIL, OK]) && expectations.length == 2) {
        ++failOk;
      }
      if (expectations.contains(FAIL) && expectations.length == 1) {
        ++fail;
      }
      if (expectations.contains(CRASH) && expectations.length == 1) {
        ++crash;
      }
      if (expectations.contains(TIMEOUT)) {
        ++timeout;
      }
    }
  }

  static void printReport() {
    if (total == 0) return;
    String report = """\
Total: $total tests
 * $skipped tests will be skipped
 * $noCrash tests are expected to be flaky but not crash
 * $pass tests are expected to pass
 * $failOk tests are expected to fail that we won't fix
 * $fail tests are expected to fail that we should fix
 * $crash tests are expected to crash that we should fix
 * $timeout tests are allowed to timeout\
""";
    print(report);
  }
}
