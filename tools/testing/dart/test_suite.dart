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
      var p = new Process.start(runnerPath, ["--list"]);
      StringInputStream stdoutStream = new StringInputStream(p.stdout);
      List<String> tests = new List<String>();
      stdoutStream.lineHandler = () {
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
    runnerPath = TestUtils.buildDir(configuration) + '/' + runnerName;
  }

  bool complexStatusMatching() => false;

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

  bool isTestFile(String filename) => filename.endsWith("Test.dart");

  bool listRecursively() => false;

  bool complexStatusMatching() => false;

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
          new Timer(enqueueCachedTests, 0);
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
    filename = filename.replaceAll('\\', '/');
    int start = filename.lastIndexOf('src/');
    if (start != -1) {
      testName = filename.substring(start + 4, filename.length - 5);
    } else if (optionsFromFile['isMultitest']) {
      start = filename.lastIndexOf('/');
      int middle = filename.lastIndexOf('_');
      testName = filename.substring(start + 1, middle) + '/' +
          filename.substring(middle + 1, filename.length - 5);
    } else {
      // This case is hit by the dartc client compilation
      // tests. These tests are pretty broken compared to the
      // rest. They use the .dart suffix in the status files. They
      // find tests in weird ways (testing that they contain "#").
      // They need to be redone.
      // directoryPath may start with '../'.
      // TODO(1058): This does not work on Windows.
      String sanitizedDirectoryPath = (directoryPath.startsWith('../')) ?
          directoryPath.substring(3) : directoryPath;
      start = filename.indexOf(sanitizedDirectoryPath);
      testName = filename.substring(start + sanitizedDirectoryPath.length + 1,
                                    filename.length);
      if (configuration['component'] != 'dartc') {
        if (testName.endsWith('.dart')) {
          testName = testName.substring(0, testName.length - 5);
        }
      }
    }
    Set<String> expectations = testExpectations.expectations(testName);
    if (configuration['report']) {
      // Tests with multiple VMOptions are counted more than once.
      for (var dummy in optionsFromFile["vmOptions"]) {
        SummaryReport.add(expectations);
      }
    }
    if (expectations.contains(SKIP)) return;

    switch (configuration['component']) {
      case 'dartium':
      case 'chromium':
      case 'frogium':
          enqueueBrowserTest(filename, testName, optionsFromFile,
                             expectations, isNegative);
        break;
      default:
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
    if (filename.endsWith('test_config.dart')) return;

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
        
  void enqueueBrowserTest(String filename,
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

    final String component = configuration['component'];
    final String testPath = new File(filename).fullPathSync();
    String dartDir = new File('.').fullPathSync();
    if (!testPath.startsWith(dartDir)) {
      dartDir = new File('..').fullPathSync();
      if (!testPath.startsWith(dartDir)) {
        print('Run test.dart from the dart directory or' +
              ' an immediate subdirectory only.');
        Expect.fail('Could not find top level dart directory.');
      }
    }

    Directory tempDir = createTemporaryDirectory(testPath, dartDir);

    String dartWrapperFilename = '${tempDir.path}/test.dart';
    String compiledDartWrapperFilename = '${tempDir.path}/test.js';
    String domLibraryImport = (component == 'chromium') ?
        '$dartDir/client/testing/unittest/dom_for_unittest.dart' : 'dart:dom';

    String htmlPath = '${tempDir.path}/test.html';
    if (!isWebTest) {
      // test.dart will import the dart test directly, if it is a library,
      // or indirectly through test_as_library.dart, if it is not.
      String dartLibraryFilename;
      if (isLibraryDefinition) {
        dartLibraryFilename = testPath;
      } else {
        dartLibraryFilename = 'test_as_library.dart';
        File file = new File('${tempDir.path}/$dartLibraryFilename');
        RandomAccessFile dartLibrary = file.openSync(FileMode.WRITE);
        dartLibrary.writeStringSync(WrapDartTestInLibrary(testPath));
        dartLibrary.closeSync();
      }  
      
      File file = new File(dartWrapperFilename);
      RandomAccessFile dartWrapper = file.openSync(FileMode.WRITE);
      dartWrapper.writeStringSync(DartTestWrapper(
          domLibraryImport,
          '$dartDir/tests/isolate/src/TestFramework.dart',
          dartLibraryFilename));
      dartWrapper.closeSync();
    } else {
      dartWrapperFilename = testPath;
      // TODO(whesse): Once test.py is retired, adjust the relative path in
      // the client/samples/dartcombat test to its css file, remove the
      // "../../" from this path, and move this out of the isWebTest guard.
      // Also remove getHtmlName, and just use test.html.
      htmlPath = '${tempDir.path}/../../${getHtmlName(filename)}';
    }
    final String scriptPath = (component == 'dartium') ?
        dartWrapperFilename : compiledDartWrapperFilename;
    // Create the HTML file for the test.
    RandomAccessFile htmlTest = new File(htmlPath).openSync(FileMode.WRITE);
    htmlTest.writeStringSync(GetHtmlContents(
        filename,
        '$dartDir/client/testing/unittest/test_controller.js',
        scriptType,
        scriptPath));
    htmlTest.closeSync();

    for (var vmOptions in optionsFromFile['vmOptions']) {
      List<String> compilerArgs;
      String compilerExecutable = TestUtils.compilerPath(configuration);
      switch (component) {
        case 'chromium':
          compilerArgs = ['--work', tempDir.path];
          if (configuration['mode'] ==  'release') {
            compilerArgs.add('--optimize');
          }
          compilerArgs.addAll(vmOptions);
          compilerArgs.add('--ignore-unrecognized-flags');
          compilerArgs.add('--out');
          compilerArgs.add(compiledDartWrapperFilename);
          compilerArgs.add(dartWrapperFilename);
          // TODO(whesse): Add --fatal-type-errors if needed.
          break;
        case 'frogium':
          compilerArgs = ['--libdir=$dartDir/frog/lib',
                          '--compile-only',
                          '--out=$compiledDartWrapperFilename'];
          compilerArgs.addAll(vmOptions);
          compilerArgs.add(dartWrapperFilename);
          break;
        case 'dartium':
          // No compilation phase.
          compilerExecutable = null;
          compilerArgs = null;
          break;
        default:
          Expect.fail('unimplemented component $component');
      }

      var args = ['--no-timeout'];
      if (component == 'dartium') {
        var dartFlags = ['--enable_asserts', '--enable_type_checks'];
        dartFlags.addAll(vmOptions);
        args.add('--dart-flags=${Strings.join(dartFlags, " ")}');
      }
      args.add(htmlPath);

      // Create BrowserTestCase and queue it.
      var testCase = new BrowserTestCase(
          testName,
          compilerExecutable,
          compilerArgs,
          getFilename(dumpRenderTreeFilename),
          args,
          configuration,
          completeHandler,
          expectations,
          optionsFromFile['isNegative']);
      doTest(testCase);
    }        
  }

  /***
   * Create a directory for the generated test.  Drop the path to the
   * dart checkout and the final ".dart" from the test path, and replace
   * all path separators with underscores.
   * All variables are block local, except tempDir.
   */
  Directory createTemporaryDirectory(String testPath, String dartDir)
  {
    String testUniqueName =
        testPath.substring(dartDir.length + 1, testPath.length - 5);
    testUniqueName = testUniqueName.replaceAll('/', '_');
    // Create '[build dir]/generated_tests/$component/$testUniqueName',
      // including any intermediate directories that don't exist.
    var generatedTestPath = ['generated_tests',
                             configuration['component'],
                             testUniqueName];

    String tempDirPath = TestUtils.buildDir(configuration);
    Directory tempDir = new Directory(tempDirPath);
    if (!tempDir.existsSync()) {
      throw new Exception('Build directory $tempDirPath does not exist.');
    }
    tempDirPath = new File(tempDirPath).fullPathSync();

    for (String subdirectory in generatedTestPath) {
      tempDirPath = '$tempDirPath/$subdirectory';
      tempDir = new Directory(tempDirPath);
      if (!tempDir.existsSync()) {
        tempDir.createSync();
      }
    }
    return tempDir;
  }

  String get scriptType() {
    switch (configuration['component']) {
      case 'dartium':
        return 'application/dart';
      case 'chromium':
      case 'frogium':
        return 'text/javascript';
      default:
        Expect.fail('Unimplemented component scriptType');
        return null;
    }
  }

  String getHtmlName(String filename) {
    return filename.replaceAll('/', '_') + configuration['component'] + '.html';
  }

  String get dumpRenderTreeFilename() {
    if (new Platform().operatingSystem() == 'macos') {
      return 'client/tests/drt/DumpRenderTree.app/Contents/' +
          'MacOS/DumpRenderTree';
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

  void activityStarted() { ++activityCount; }

  void activityCompleted() {
    if (--activityCount == 0) {
      directoryListingDone(true);
    }
  }

  String shellPath() => TestUtils.compilerPath(configuration);

  List<String> additionalOptions() {
    // TODO(ager): potentially register cleanup action to delete the temporary
    // directories?
    var tempDir = new Directory('');
    tempDir.createTempSync();
    return
        ['-check-only', '-fatal-type-errors', '-Werror', '-out', tempDir.path];
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


class JUnitTestSuite implements TestSuite {
  Map configuration;
  String suiteName;
  String directoryPath;
  String statusFilePath;
  String dartDir;
  String buildDir;
  String classPath;
  List<String> testClasses;
  Function doTest;
  Function doDone;
  TestExpectations testExpectations;

  JUnitTestSuite(Map this.configuration,
                 String this.suiteName,
                 String this.directoryPath,
                 String this.statusFilePath);

  bool isTestFile(String filename) => filename.endsWith("Tests.java") &&
      !filename.contains('com/google/dart/compiler/vm') &&
      !filename.contains('com/google/dart/corelib/SharedTests.java');

  void forEachTest(Function onTest,
                   Map testCacheIgnored,
                   [Function onDone = null]) {
    doTest = onTest;
    doDone = (onDone != null) ? onDone : (() => null);
    
    if (configuration['component'] != 'dartc') {
      // Do nothing.  Asynchronously report that the suite is enqueued.
      new Timer((timerUnused){ doDone(); }, 0);
      return;
    }
    RegExp pattern = configuration['selectors']['dartc'];
    if (!pattern.hasMatch('junit_tests')) {
      new Timer((timerUnused){ doDone(); }, 0);
      return;
    }

    dartDir = new File('.').fullPathSync();
    buildDir = TestUtils.buildDir(configuration);
    computeClassPath();
    testClasses = <String>[];
    // Do not read the status file.
    // All exclusions are hardcoded in this script, as they are in testcfg.py.
    processDirectory();
  }

  void processDirectory() {
    directoryPath = getDirname(directoryPath);
    Directory dir = new Directory(directoryPath);

    dir.errorHandler = (s) {
      throw s;
    };
    dir.fileHandler = processFile;
    dir.doneHandler = createTest;
    dir.list(recursive: true);
  }

  void processFile(String filename) {
    if (!isTestFile(filename)) return;

    int index = filename.indexOf('compiler/javatests/com/google/dart');
    if (index != -1) {
      String testRelativePath =
          filename.substring(index + 'compiler/javatests/'.length,
                             filename.length - '.java'.length);
      String testClass = testRelativePath.replaceAll('/', '.');
      testClasses.add(testClass);
    }
  }
      
  void createTest(successIgnored) {
    String d8 = '$dartDir/$buildDir/d8${TestUtils.executableSuffix}';
    List<String> args = <String>[
        '-ea',
        '-classpath', classPath,
        '-Dcom.google.dart.runner.d8=$d8',
        '-Dcom.google.dart.corelib.SharedTests.test_py=$dartDir/tools/test.py',
        'org.junit.runner.JUnitCore'];
    args.addAll(testClasses);
          
    doTest(new TestCase(suiteName,
                        'java',
                        args,
                        configuration,
                        completeHandler,
                        new Set<String>.from([PASS])));
    doDone();
  }

  void completeHandler(TestCase testCase) {
  }

  void computeClassPath() {
    classPath = Strings.join(
        ['$buildDir/compiler/lib/dartc.jar',
         '$buildDir/compiler/lib/corelib.jar',
         '$buildDir/compiler-tests.jar',
         '$buildDir/closure_out/compiler.jar',
         // Third party libraries.
         'third_party/args4j/2.0.12/args4j-2.0.12.jar',
         'third_party/guava/r09/guava-r09.jar',
         'third_party/json/r2_20080312/json.jar',
         'third_party/rhino/1_7R3/js.jar',
         'third_party/hamcrest/v1_3/hamcrest-core-1.3.0RC2.jar',
         'third_party/hamcrest/v1_3/hamcrest-generator-1.3.0RC2.jar',
         'third_party/hamcrest/v1_3/hamcrest-integration-1.3.0RC2.jar',
         'third_party/hamcrest/v1_3/hamcrest-library-1.3.0RC2.jar',
         'third_party/junit/v4_8_2/junit.jar'],
        ':');  // Path separator.
  }
}


class TestUtils {
  static String get executableSuffix() =>
      (new Platform().operatingSystem() == 'windows') ? '.exe' : '';      

  static String executableName(Map configuration) {
    String postfix = executableSuffix;
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

  static String compilerName(Map configuration) {
    String postfix =
        (new Platform().operatingSystem() == 'windows') ? '.exe' : '';
    switch (configuration['component']) {
      case 'chromium':
      case 'dartc':
        return 'compiler/bin/dartc$postfix';
      case 'frogium':
        return 'frog/bin/frogsh$postfix';
      default:
        throw "Unknown compiler for: ${configuration['component']}";
    }
  }

  static String dartShellFileName(Map configuration) {
    var name = '${buildDir(configuration)}/${executableName(configuration)}';
    if (!(new File(name)).existsSync()) {
      throw "Executable '$name' does not exist";
    }
    return name;
  }

  static String compilerPath(Map configuration) {
    if (configuration['component'] == 'dartium') {
      return null;  // No separate compiler for dartium tests.
    }
    var name = '${buildDir(configuration)}/${compilerName(configuration)}';
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
    buildDir += configuration['arch'];
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
      args.add("--leg_only");
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
