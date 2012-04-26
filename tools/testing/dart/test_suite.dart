// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Classes and methods for enumerating and preparing tests.
 *
 * This library includes:
 *
 * - Creating tests by listing all the Dart files in certain directories,
 *   and creating [TestCase]s for those files that meet the relevant criteria.
 * - Preparing tests, including copying files and frameworks to temporary
 *   directories, and computing the command line and arguments to be run.
 */
#library("test_suite");

#import("dart:io");
#import("dart:builtin");
#import("dart:isolate");
#import("status_file_parser.dart");
#import("test_runner.dart");
#import("multitest.dart");
#import("drt_updater.dart");

#source("browser_test.dart");


// TODO(rnystrom): Add to dart:core?
/**
 * A simple function that tests [arg] and returns `true` or `false`.
 */
typedef bool Predicate<T>(T arg);


/**
 * A TestSuite represents a collection of tests.  It creates a [TestCase]
 * object for each test to be run, and passes the test cases to a callback.
 *
 * Most TestSuites represent a directory or directory tree containing tests,
 * and a status file containing the expected results when these tests are run.
 */
interface TestSuite {
  /**
   * Call the callback function onTest with a [TestCase] argument for each
   * test in the suite.  When all tests have been processed, call [onDone].
   *
   * The [testCache] argument provides a persistent store that can be used to
   * cache information about the test suite, so that directories do not need
   * to be listed each time.  If the tests require a temporary directory for
   * their files, they can get one from [globalTempDir].
   */
  void forEachTest(Function onTest, Map testCache, String globalTempDir(),
                   [Function onDone]);
}


class CCTestListerIsolate extends Isolate {
  CCTestListerIsolate() : super.heavy();

  void main() {
    port.receive((String runnerPath, SendPort replyTo) {
      var p = new Process.start(runnerPath, ["--list"]);
      StringInputStream stdoutStream = new StringInputStream(p.stdout);
      List<String> tests = new List<String>();
      stdoutStream.onLine = () {
        String line = stdoutStream.readLine();
        while (line != null) {
          tests.add(line);
          line = stdoutStream.readLine();
        }
      };
      p.onError = (error) {
        print("Failed to list tests: $runnerPath --list");
        replyTo.send("");
      };
      p.onExit = (code) {
        if (code < 0) {
          print("Failed to list tests: $runnerPath --list");
          replyTo.send("");
        }
        for (String test in tests) {
          replyTo.send(test);
        }
        replyTo.send("");
      };
      port.close();
    });
  }
}


/**
 * A specialized [TestSuite] that runs tests written in C to unit test
 * the Dart virtual machine and its API.
 *
 * The tests are compiled into a monolithic executable by the build step.
 * The executable lists its tests when run with the --list command line flag.
 * Individual tests are run by specifying them on the command line.
 */
class CCTestSuite implements TestSuite {
  Map configuration;
  final String suiteName;
  String runnerPath;
  final String dartDir;
  List<String> statusFilePaths;
  Function doTest;
  Function doDone;
  ReceivePort receiveTestName;
  TestExpectations testExpectations;

  CCTestSuite(Map this.configuration,
              String this.suiteName,
              String runnerName,
              List<String> this.statusFilePaths)
      : dartDir = TestUtils.dartDir() {
    runnerPath = TestUtils.buildDir(configuration) + '/' + runnerName;
  }

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
                          [new Command(runnerPath, args)],
                          configuration,
                          completeHandler,
                          expectations));
    }
  }

  void forEachTest(Function onTest, Map testCache, String globalTempDir(),
                   [Function onDone]) {
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

    testExpectations = new TestExpectations();
    for (var statusFilePath in statusFilePaths) {
      ReadTestExpectationsInto(testExpectations,
                               '$dartDir/$statusFilePath',
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
  bool hasRuntimeErrors;
  Set<String> multitestOutcome;

  TestInformation(this.filename, this.optionsFromFile, this.isNegative,
                  this.isNegativeIfChecked, this.hasFatalTypeErrors,
                  this.hasRuntimeErrors, this.multitestOutcome);
}


/**
 * A standard [TestSuite] implementation that searches for tests in a
 * directory, and creates [TestCase]s that compile and/or run them.
 */
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
  final String dartDir;
  Function globalTemporaryDirectory;
  Predicate<String> isTestFilePredicate;

  StandardTestSuite(Map this.configuration,
                    String this.suiteName,
                    String this.directoryPath,
                    List<String> this.statusFilePaths,
                    [Predicate<String> this.isTestFilePredicate])
    : dartDir = TestUtils.dartDir();

  /**
   * Creates a test suite whose file organization matches an expected structure.
   * To use this, your suite should look like:
   *
   *     dart/
   *       path/
   *         to/
   *           mytestsuite/
   *             mytestsuite.status
   *             example1_test.dart
   *             example2_test.dart
   *             example3_test.dart
   *
   * The important parts:
   *
   * * The leaf directory name is the name of your test suite.
   * * The status file uses the same name.
   * * Test files are directly in that directory and end in "_test.dart".
   *
   * If you follow that convention, then you can construct one of these like:
   *
   * new StandardTestSuite.forDirectory(configuration, 'path/to/mytestsuite');
   *
   * instead of having to create a custom [StandardTestSuite] subclass. In
   * particular, if you add 'path/to/mytestsuite' to [TEST_SUITE_DIRECTORIES]
   * in test.dart, this will all be set up for you.
   */
  factory StandardTestSuite.forDirectory(
      Map configuration, String directory) {
    final name = directory.substring(directory.lastIndexOf('/') + 1);

    return new StandardTestSuite(configuration,
        name, directory, ['$directory/$name.status'],
        (filename) => filename.endsWith('_test.dart'));
  }

  /**
   * The default implementation assumes a file is a test if
   * it ends in "Test.dart".
   */
  bool isTestFile(String filename) {
    // Use the specified predicate, if provided.
    if (isTestFilePredicate != null) return isTestFilePredicate(filename);

    return filename.endsWith("Test.dart");
  }

  bool listRecursively() => false;

  String shellPath() => TestUtils.dartShellFileName(configuration);

  List<String> additionalOptions(String filename) => [];

  void forEachTest(Function onTest, Map testCache, String globalTempDir(),
                   [Function onDone = null]) {
    // If DumpRenderTree/Dartium is required, and not yet updated,
    // wait for update.
    var updater = runtimeUpdater(configuration['runtime']);
    if (updater !== null && !updater.updated) {
      Expect.isTrue(updater.isActive);
      updater.onUpdated.add(() {
        forEachTest(onTest, testCache, globalTempDir, onDone);
      });
      return;
    }

    doTest = onTest;
    doDone = (onDone != null) ? onDone : (() => null);
    globalTemporaryDirectory = globalTempDir;

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
          new Timer(0, enqueueCachedTests);
        }
      }
    }

    // Read test expectations from status files.
    testExpectations = new TestExpectations();
    for (var statusFilePath in statusFilePaths) {
      ReadTestExpectationsInto(testExpectations,
                               '$dartDir/$statusFilePath',
                               configuration,
                               statusFileRead);
    }
  }

  void processDirectory() {
    directoryPath = '$dartDir/$directoryPath';
    Directory dir = new Directory(directoryPath);
    dir.onError = (s) {
      throw s;
    };
    dir.exists((bool exists) {
      if (!exists) {
        print('Directory containing tests not found: $directoryPath');
        directoryListingDone(false);
      } else {
        dir.onFile = processFile;
        dir.onDone = directoryListingDone;
        dir.list(recursive: listRecursively());
      }
    });
  }

  void enqueueTestCaseFromTestInformation(TestInformation info) {
    var filename = info.filename;
    var optionsFromFile = info.optionsFromFile;
    var isNegative = info.isNegative;

    // Look up expectations in status files using a modified file path.
    String testName;
    filename = filename.replaceAll('\\', '/');

    // See if there's a 'src' directory inside the 'tests' one.
    int testsStart = filename.lastIndexOf('tests/');
    int start = filename.lastIndexOf('src/');
    if (start > testsStart) {
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
      // TODO(1058): This does not work on Windows.
      start = filename.indexOf(directoryPath);
      if (start != -1) {
        testName = filename.substring(start + directoryPath.length + 1);
      } else {
        testName = filename;
      }

      if (configuration['compiler'] != 'dartc') {
        if (testName.endsWith('.dart')) {
          testName = testName.substring(0, testName.length - 5);
        }
      }
    }
    int shards = configuration['shards'];
    if (shards > 1) {
      int shard = configuration['shard'];
      if (testName.hashCode() % shards != shard - 1) {
        return;
      }
    }

    Set<String> expectations = testExpectations.expectations(testName);
    if (configuration['report']) {
      // Tests with multiple VMOptions are counted more than once.
      for (var dummy in getVmOptions(optionsFromFile)) {
        if (TestUtils.isBrowserRuntime(configuration['runtime']) &&
            optionsFromFile['isMultitest']) {
          break;  // Browser tests skip multitests.
        }
        SummaryReport.add(expectations);
      }
    }
    if (expectations.contains(SKIP)) return;

    if (TestUtils.isBrowserRuntime(configuration['runtime'])) {
      enqueueBrowserTest(info, testName, expectations);
    } else {
      enqueueStandardTest(info, testName, expectations);
    }
  }

  void enqueueStandardTest(TestInformation info,
                           String testName,
                           Set<String> expectations) {
    bool isNegative = info.isNegative ||
        (configuration['checked'] && info.isNegativeIfChecked);

    if (configuration['compiler'] == 'dartc') {
      // dartc can detect static type warnings by the
      // format of the error line
      if (info.hasFatalTypeErrors) {
        isNegative = true;
      } else if (info.hasRuntimeErrors) {
        isNegative = false;
      }
    }

    var argumentLists = argumentListsFromFile(info.filename,
                                              info.optionsFromFile);

    for (var args in argumentLists) {
      doTest(new TestCase('$suiteName/$testName',
                          makeCommands(info, args),
                          configuration,
                          completeHandler,
                          expectations,
                          isNegative,
                          info));
    }
  }

  List<Command> makeCommands(TestInformation info, var args) {
    if (configuration['compiler'] == 'dart2js') {
      args = new List.from(args);
      String testPath =
          new File(info.filename).fullPathSync().replaceAll('\\', '/');
      Directory tempDir = createOutputDirectory(testPath, '');
      args.add('--out=${tempDir.path}/out.js');
      List<Command> commands = <Command>[new Command(shellPath(), args)];
      if (configuration['runtime'] == 'd8') {
        var d8 = TestUtils.d8FileName(configuration);
        commands.add(new Command(d8, ['${tempDir.path}/out.js']));
      }
      return commands;
    } else {
      return <Command>[new Command(shellPath(), args)];
    }
  }

  Function makeTestCaseCreator(Map optionsFromFile) {
    return (String filename,
            bool isNegative,
            [bool isNegativeIfChecked = false,
             bool hasFatalTypeErrors = false,
             bool hasRuntimeErrors = false,
             Set<String> multitestOutcome = null]) {
      // Cache the test information for each test case.
      var info = new TestInformation(filename,
                                     optionsFromFile,
                                     isNegative,
                                     isNegativeIfChecked,
                                     hasFatalTypeErrors,
                                     hasRuntimeErrors,
                                     multitestOutcome);
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

    var optionsFromFile = readOptionsFromFile(filename);
    Function createTestCase = makeTestCaseCreator(optionsFromFile);

    if (optionsFromFile['isMultitest']) {
      testGeneratorStarted();
      DoMultitest(filename,
                  TestUtils.buildDir(configuration),
                  directoryPath,
                  createTestCase,
                  testGeneratorDone);
    } else {
      createTestCase(filename, optionsFromFile['isNegative']);
    }
  }

  /**
   * The [StandardTestSuite] has support for tests that
   * compile a test from Dart to Javascript, and then run the resulting
   * Javascript.  This function creates a working directory to hold the
   * Javascript version of the test, and copies the appropriate framework
   * files to that directory.  It creates a [BrowserTestCase], which has
   * two sequential steps to be run by the [ProcessQueue when] the test is
   * executed: a compilation
   * step and an execution step, both with the appropriate executable and
   * arguments.
   */
  void enqueueBrowserTest(TestInformation info,
                          String testName,
                          Set<String> expectations) {
    Map optionsFromFile = info.optionsFromFile;
    String filename = info.filename;
    if (optionsFromFile['isMultitest']) return;
    bool isWebTest = optionsFromFile['containsDomImport'];
    bool isLibraryDefinition = optionsFromFile['isLibraryDefinition'];
    if (!isLibraryDefinition && optionsFromFile['containsSourceOrImport']) {
      print('Warning for $filename: Browser tests require #library ' +
            'in any file that uses #import, #source, or #resource');
    }

    final String compiler = configuration['compiler'];
    final String runtime = configuration['runtime'];
    final String testPath =
        new File(filename).fullPathSync().replaceAll('\\', '/');

    for (var vmOptions in getVmOptions(optionsFromFile)) {
      // Create a unique temporary directory for each set of vmOptions.
      // TODO(dart:429): Replace separate replaceAlls with a RegExp when
      // replaceAll(RegExp, String) is implemented.
      String optionsName = '';
      if (getVmOptions(optionsFromFile).length > 1) {
          optionsName = Strings.join(vmOptions, '-').replaceAll('-','')
                                                    .replaceAll('=','')
                                                    .replaceAll('/','');
      }
      Directory tempDir = createOutputDirectory(testPath, optionsName);

      String dartWrapperFilename = '${tempDir.path}/test.dart';
      String compiledDartWrapperFilename = '${tempDir.path}/test.js';

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
        dartWrapper.writeStringSync(
            DartTestWrapper(dartDir, dartLibraryFilename));
        dartWrapper.closeSync();
      } else {
        dartWrapperFilename = testPath;
        // TODO(whesse): Once test.py is retired, adjust the relative path in
        // the client/samples/dartcombat test to its css file, remove the
        // "../../" from this path, and move this out of the isWebTest guard.
        // Also remove getHtmlName, and just use test.html.
        // TODO(efortuna): this shortening of htmlFilename is a band-aid until
        // the above TODO gets fixed. Windows cannot have paths that are longer
        // than 260 characters, and without this hack, we were running past the
        // the limit.
        String htmlFilename = getHtmlName(filename);
        while ('${tempDir.path}/../$htmlFilename'.length >= 260) {
          htmlFilename = htmlFilename.substring(htmlFilename.length~/2);
        }
        htmlPath = '${tempDir.path}/../$htmlFilename';
      }
      final String scriptPath = (compiler == 'none') ?
          dartWrapperFilename : compiledDartWrapperFilename;
      // Create the HTML file for the test.
      RandomAccessFile htmlTest = new File(htmlPath).openSync(FileMode.WRITE);
      String filePrefix = '';
      if (Platform.operatingSystem() == 'windows') {
        // Firefox on Windows does not like absolute file path names that start
        // with 'C:' adding 'file:///' solves the problem.
        filePrefix = 'file:///';
      }
      htmlTest.writeStringSync(GetHtmlContents(
          filename,
          '$filePrefix$dartDir/lib/unittest/test_controller.js',
          scriptType,
          filePrefix + scriptPath));
      htmlTest.closeSync();

      // Construct the command(s) that compile all the inputs needed by the
      // browser test. For running Dart in DRT, this will be noop commands.
      List<Command> commands = [];
      if (compiler != 'none') {
        commands.add(_compileCommand(
            dartWrapperFilename, compiledDartWrapperFilename,
            compiler, tempDir.path, vmOptions));

        // some tests require compiling multiple input scripts.
        List<String> otherScripts = optionsFromFile['otherScripts'];
        for (String name in otherScripts) {
          int end = filename.lastIndexOf('/');
          if (end == -1) {
            print('Warning: error processing "OtherScripts" of $filename.');
            print('Skipping test ($testName).');
            return;
          }
          String dir = filename.substring(0, end);
          end = name.lastIndexOf('.dart');
          if (end == -1) {
            print('Warning: error processing "OtherScripts" in $filename.');
            print('Skipping test ($testName).');
            return;
          }
          String compiledName = '${name.substring(0, end)}.js';
          commands.add(_compileCommand(
              '$dir/$name', '${tempDir.path}/$compiledName',
              compiler, tempDir.path, vmOptions));
        }
      }

      // Construct the command that executes the browser test
      List<String> args;
      if (runtime == 'ie' || runtime == 'ff' || runtime == 'chrome' ||
          runtime == 'safari' || runtime == 'opera' || runtime == 'dartium') {
        args = ['$dartDir/tools/testing/run_selenium.py',
            '--browser=$runtime',
            '--timeout=${configuration["timeout"] - 2}',
            '--out=$htmlPath'];
        if (runtime == 'dartium') {
          args.add('--executable=$dartiumFilename');
        }
      } else {
        args = [
            '$dartDir/tools/testing/drt-trampoline.py',
            dumpRenderTreeFilename,
            '--no-timeout'
        ];
        if (runtime == 'drt' && compiler == 'none') {
          var dartFlags = ['--ignore-unrecognized-flags'];
          if (configuration["checked"]) {
            dartFlags.add('--enable_asserts');
            dartFlags.add("--enable_type_checks");
          }
          dartFlags.addAll(vmOptions);
          args.add('--dart-flags=${Strings.join(dartFlags, " ")}');
        }
        args.add(htmlPath);
      }
      commands.add(new Command('python', args));

      // Create BrowserTestCase and queue it.
      var testCase = new BrowserTestCase(testName, commands, configuration,
          completeHandler, expectations, optionsFromFile['isNegative']);
      doTest(testCase);
    }
  }

  /** Helper to create a compilation command for a single input file. */
  Command _compileCommand(String inputFile, String outputFile,
      String compiler, String dir, var vmOptions) {
    String executable = TestUtils.compilerPath(configuration);
    List<String> args = TestUtils.standardOptions(configuration);
    switch (compiler) {
      case 'frog':
        String libdir = configuration['froglib'];
        if (libdir == '') {
          libdir = '$dartDir/frog/lib';
        }
        args.addAll(['--libdir=$libdir',
                     '--compile-only',
                     '--out=$outputFile']);
        args.addAll(vmOptions);
        args.add(inputFile);
        break;
      case 'dart2js':
        args.add('--out=$outputFile');
        args.add(inputFile);
        break;
      default:
        Expect.fail('unimplemented compiler $compiler');
    }
    if (executable.endsWith('.dart')) {
      // Run the compiler script via the Dart VM.
      args.insertRange(0, 1, executable);
      executable = TestUtils.dartShellFileName(configuration);
    }
    return new Command(executable, args);
  }

  bool get requiresCleanTemporaryDirectory() =>
      configuration['compiler'] == 'dartc';

  /**
   * Create a directory for the generated test.  If a Dart language test
   * needs to be run in a browser, the Dart test needs to be embedded in
   * an HTML page, with a testing framework based on scripting and DOM events.
   * These scripts and pages are written to a generated_test directory,
   * usually inside the build directory of the checkout.
   *
   * Some tests, such as those using the dartc compiler, need to be run
   * with an empty directory as the compiler's work directory.  These
   * tests are copied to a subdirectory of a system-provided temporary
   * directory, which is deleted at the end of the test run unless the
   * --keep-temporary-files flag is given.
   *
   * Those tests which are already HTML web applications (web tests), with
   * resources including CSS files and HTML files, need to be compiled into
   * a work directory where the relative URLS to the resources work.
   * We use a subdirectory of the build directory that is the same number
   * of levels down in the checkout as the original path of the web test.
   */
  Directory createOutputDirectory(String testPath, String optionsName) {
    String testUniqueName =
        testPath.substring(dartDir.length + 1, testPath.length - 5);
    testUniqueName = testUniqueName.replaceAll('/', '_');
    if (!optionsName.isEmpty()) {
      testUniqueName += '-$optionsName';
    }

    // Create '[build dir]/generated_tests/$compiler-$runtime/$testUniqueName',
    // including any intermediate directories that don't exist.
    var generatedTestPath = ['generated_tests',
                             configuration['compiler'] + '-' +
                             configuration['runtime'],
                             testUniqueName];

    String tempDirPath = TestUtils.buildDir(configuration);
    if (requiresCleanTemporaryDirectory) {
      tempDirPath = globalTemporaryDirectory();
      String debugMode =
          (configuration['mode'] == 'debug') ? 'Debug_' : 'Release_';
      var temp = ['${debugMode}_${configuration["arch"]}'];
      temp.addAll(generatedTestPath);
      generatedTestPath = temp;
    }
    Directory tempDir = new Directory(tempDirPath);
    if (!tempDir.existsSync()) {
      // Dartium tests can be run with no build step, with no output directory.
      // This special case builds the build directory that should be there.
      var buildPath = tempDirPath.split('/');
      tempDirPath = buildPath[0];
      if (tempDirPath == '') {
        throw new Exception(
            'Non-relative path to build directory in test_suite.dart');
      }
      if (buildPath.length > 1) {
        buildPath.removeRange(0, 1);
        if (buildPath.last() == '') buildPath.removeLast();
        buildPath.addAll(generatedTestPath);
        generatedTestPath = buildPath;
      }
      tempDir = new Directory(tempDirPath);
      if (!tempDir.existsSync()) {
        tempDir.createSync();
      }
    }
    tempDirPath = new File(tempDirPath).fullPathSync().replaceAll('\\', '/');
    return TestUtils.mkdirRecursive(tempDirPath,
                                    Strings.join(generatedTestPath, '/'));
  }

  String get scriptType() {
    switch (configuration['compiler']) {
      case 'none':
        return 'application/dart';
      case 'frog':
      case 'dart2js':
      case 'dartc':
        return 'text/javascript';
      default:
        Expect.fail('Non-web runtime, so no scriptType for: ' +
            '${configuration["compiler"]}');
        return null;
    }
  }

  bool get hasRuntime() {
    switch(configuration['runtime']) {
      case null:
        Expect.fail("configuration['runtime'] is not set");
      case 'none':
        return false;
      default:
        return true;
    }
  }

  String getHtmlName(String filename) {
    return filename.replaceAll('/', '_').replaceAll(':', '_')
        .replaceAll('\\', '_') + configuration['compiler'] + '-' +
        configuration['runtime'] + '.html';
  }

  String get dumpRenderTreeFilename() {
    if (configuration['drt'] != '') {
      return configuration['drt'];
    }
    if (Platform.operatingSystem() == 'macos') {
      return '$dartDir/client/tests/drt/DumpRenderTree.app/Contents/'
          'MacOS/DumpRenderTree';
    }
    return '$dartDir/client/tests/drt/DumpRenderTree';
  }

  String get dartiumFilename() {
    if (configuration['dartium'] != '') {
      return configuration['dartium'];
    }
    if (Platform.operatingSystem() == 'macos') {
      return '$dartDir/client/tests/dartium/Chromium.app/Contents/'
          'MacOS/Chromium';
    }
    return '$dartDir/client/tests/dartium/chrome';
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
                                           Map optionsFromFile) {
    List args = TestUtils.standardOptions(configuration);
    args.addAll(additionalOptions(filename));
    if (configuration['compiler'] == 'dartc') {
      args.add('--error_format');
      args.add('machine');
    }
    if ((configuration['compiler'] == 'frog')
        && (configuration['runtime'] == 'none')) {
      args.add('--compile-only');
    }

    bool isMultitest = optionsFromFile["isMultitest"];
    List<String> dartOptions = optionsFromFile["dartOptions"];
    List<List<String>> vmOptionsList = getVmOptions(optionsFromFile);
    Expect.isTrue(!isMultitest || dartOptions == null);
    if (dartOptions == null) {
      args.add(filename);
    } else {
      var executable_name = dartOptions[0];
      // TODO(ager): Get rid of this hack when the runtime checkout goes away.
      var file = new File(executable_name);
      if (!file.existsSync()) {
        executable_name = '../$executable_name';
        Expect.isTrue(new File(executable_name).existsSync());
        dartOptions[0] = executable_name;
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

  Map readOptionsFromFile(String filename) {
    RegExp testOptionsRegExp = const RegExp(@"// VMOptions=(.*)");
    RegExp dartOptionsRegExp = const RegExp(@"// DartOptions=(.*)");
    RegExp otherScriptsRegExp = const RegExp(@"// OtherScripts=(.*)");
    RegExp multiTestRegExp = const RegExp(@"/// [0-9][0-9]:(.*)");
    RegExp staticTypeRegExp =
        const RegExp(@"/// ([0-9][0-9]:){0,1}\s*static type warning");
    RegExp compileTimeRegExp =
        const RegExp(@"/// ([0-9][0-9]:){0,1}\s*compile-time error");
    RegExp staticCleanRegExp = const RegExp(@"// @static-clean");
    RegExp leadingHashRegExp = const RegExp(@"^#", multiLine: true);
    RegExp isolateStubsRegExp = const RegExp(@"// IsolateStubs=(.*)");
    RegExp domImportRegExp =
        const RegExp(@"^#import.*(dart:(dom|html)|html\.dart).*\)",
                     multiLine: true);
    RegExp libraryDefinitionRegExp =
        const RegExp(@"^#library\(", multiLine: true);
    RegExp sourceOrImportRegExp =
        const RegExp(@"^#(source|import|resource)\(", multiLine: true);

    // Read the entire file into a byte buffer and transform it to a
    // String. This will treat the file as ascii but the only parts
    // we are interested in will be ascii in any case.
    RandomAccessFile file = new File(filename).openSync(FileMode.READ);
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
    bool isStaticClean = false;

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

    matches = staticCleanRegExp.allMatches(contents);
    for (var match in matches) {
      if (isStaticClean) {
        throw new Exception(
            'More than one "// @static-clean=" line in test $filename');
      }
      isStaticClean = true;
    }

    List<String> otherScripts = new List<String>();
    matches = otherScriptsRegExp.allMatches(contents);
    for (var match in matches) {
      otherScripts.addAll(match[1].split(' ').filter((e) => e != ''));
    }

    if (contents.contains("@compile-error")) {
      isNegative = true;
    }

    if (contents.contains("@runtime-error") && hasRuntime) {
      isNegative = true;
    }

    bool isMultitest = multiTestRegExp.hasMatch(contents);
    bool containsLeadingHash = leadingHashRegExp.hasMatch(contents);
    Match isolateMatch = isolateStubsRegExp.firstMatch(contents);
    String isolateStubs = isolateMatch != null ? isolateMatch[1] : '';
    bool containsDomImport = domImportRegExp.hasMatch(contents);
    bool isLibraryDefinition = libraryDefinitionRegExp.hasMatch(contents);
    bool containsSourceOrImport = sourceOrImportRegExp.hasMatch(contents);
    int numStaticTypeAnnotations = 0;
    for (var i in staticTypeRegExp.allMatches(contents)) {
      numStaticTypeAnnotations++;
    }
    int numCompileTimeAnnotations = 0;
    for (var i in compileTimeRegExp.allMatches(contents)) {
      numCompileTimeAnnotations++;
    }

    return { "vmOptions": result,
             "dartOptions": dartOptions,
             "isNegative": isNegative,
             "isStaticClean" : isStaticClean,
             "otherScripts": otherScripts,
             "isMultitest": isMultitest,
             "containsLeadingHash": containsLeadingHash,
             "isolateStubs": isolateStubs,
             "containsDomImport": containsDomImport,
             "isLibraryDefinition": isLibraryDefinition,
             "containsSourceOrImport": containsSourceOrImport,
             "numStaticTypeAnnotations": numStaticTypeAnnotations,
             "numCompileTimeAnnotations": numCompileTimeAnnotations};
  }

  List<List<String>> getVmOptions(Map optionsFromFile) {
    if (configuration['compiler'] == 'dart2js') {
      return [[]];
    } else {
      return optionsFromFile['vmOptions'];
    }
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

  List<String> additionalOptions(String filename) {
    return ['--fatal-warnings', '--fatal-type-errors'];
  }

  void processDirectory() {
    directoryPath = '$dartDir/$directoryPath';
    // Enqueueing the directory listers is an activity.
    activityStarted();
    for (String testDir in _testDirs) {
      Directory dir = new Directory("$directoryPath/$testDir");
      if (dir.existsSync()) {
        activityStarted();
        dir.onError = (s) {
          throw s;
        };
        dir.onFile = processFile;
        dir.onDone = (ignore) => activityCompleted();
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
  final String dartDir;
  String buildDir;
  String classPath;
  List<String> testClasses;
  Function doTest;
  Function doDone;
  TestExpectations testExpectations;

  JUnitTestSuite(Map this.configuration,
                 String this.suiteName,
                 String this.directoryPath,
                 String this.statusFilePath)
      : dartDir = TestUtils.dartDir();

  bool isTestFile(String filename) => filename.endsWith("Tests.java") &&
      !filename.contains('com/google/dart/compiler/vm') &&
      !filename.contains('com/google/dart/corelib/SharedTests.java');

  void forEachTest(Function onTest,
                   Map testCacheIgnored,
                   String globalTempDir(),
                   [Function onDone = null]) {
    doTest = onTest;
    doDone = (onDone != null) ? onDone : (() => null);

    if (configuration['compiler'] != 'dartc') {
      // Do nothing.  Asynchronously report that the suite is enqueued.
      new Timer(0, (timerUnused){ doDone(); });
      return;
    }
    RegExp pattern = configuration['selectors']['dartc'];
    if (!pattern.hasMatch('junit_tests')) {
      new Timer(0, (timerUnused){ doDone(); });
      return;
    }

    buildDir = TestUtils.buildDir(configuration);
    computeClassPath();
    testClasses = <String>[];
    // Do not read the status file.
    // All exclusions are hardcoded in this script, as they are in testcfg.py.
    processDirectory();
  }

  void processDirectory() {
    directoryPath = '$dartDir/$directoryPath';
    Directory dir = new Directory(directoryPath);

    dir.onError = (s) {
      throw s;
    };
    dir.onFile = processFile;
    dir.onDone = createTest;
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
    var sdkDir = "$buildDir/dart-sdk".trim();
    List<String> args = <String>[
        '-ea',
        '-classpath', classPath,
        '-Dcom.google.dart.sdk=$sdkDir',
        '-Dcom.google.dart.corelib.SharedTests.test_py=' +
            dartDir + '/tools/test.py',
        'org.junit.runner.JUnitCore'];
    args.addAll(testClasses);
    
    // Lengthen the timeout for JUnit tests.  It is normal for them
    // to run for a few minutes.
    Map updatedConfiguration = new Map();
    configuration.forEach((key, value) {
      updatedConfiguration[key] = value;
    });
    updatedConfiguration['timeout'] *= 2;
    doTest(new TestCase(suiteName,
                        [new Command('java', args)],
                        updatedConfiguration,
                        completeHandler,
                        new Set<String>.from([PASS])));
    doDone();
  }

  void completeHandler(TestCase testCase) {
  }

  void computeClassPath() {
    classPath = Strings.join(
        ['$buildDir/compiler/lib/dartc.jar',
         '$buildDir/compiler-tests.jar',
         '$buildDir/closure_out/compiler.jar',
         // Third party libraries.
         '$dartDir/third_party/args4j/2.0.12/args4j-2.0.12.jar',
         '$dartDir/third_party/guava/r09/guava-r09.jar',
         '$dartDir/third_party/rhino/1_7R3/js.jar',
         '$dartDir/third_party/hamcrest/v1_3/hamcrest-core-1.3.0RC2.jar',
         '$dartDir/third_party/hamcrest/v1_3/hamcrest-generator-1.3.0RC2.jar',
         '$dartDir/third_party/hamcrest/v1_3/hamcrest-integration-1.3.0RC2.jar',
         '$dartDir/third_party/hamcrest/v1_3/hamcrest-library-1.3.0RC2.jar',
         '$dartDir/third_party/junit/v4_8_2/junit.jar'],
        ':');  // Path separator.
  }
}


class TestUtils {
  /**
   * Creates a directory using a [relativePath] to an existing
   * [base] directory if that [relativePath] does not already exist.
   */
  static Directory mkdirRecursive(String base, String relativePath) {
    Directory baseDir = new Directory(base);
    Expect.isTrue(baseDir.existsSync(),
      "Expected ${base} to already exist");
    var tempDir = new Directory(base);
    for (String dir in relativePath.split('/')) {
      base = "$base/$dir";
      tempDir = new Directory(base);
      if (!tempDir.existsSync()) {
          tempDir.createSync();
      }
      Expect.isTrue(tempDir.existsSync(), "Failed to create ${tempDir.path}");
    }
    return tempDir;
  }

  /**
   * Copy a [source] file to a new place.
   * Assumes that the directory for [dest] already exists.
   */
  static void copyFile(File source, File dest) {
    List contents = source.readAsBytesSync();
    RandomAccessFile handle = dest.openSync(FileMode.WRITE);
    handle.writeListSync(contents, 0, contents.length);
    handle.closeSync();
  }

  static String executableSuffix(String executable) {
    if (Platform.operatingSystem() == 'windows') {
      if (executable == 'd8' || executable == 'vm' || executable == 'none') {
        return '.exe';
      } else {
        return '.bat';
      }
    }
    return '';
  }

  static String executableName(Map configuration) {
    String suffix = executableSuffix(configuration['compiler']);
    switch (configuration['compiler']) {
      case 'none':
        return 'dart$suffix';
      case 'dartc':
        return 'compiler/bin/dartc$suffix';
      case 'dart2js':
        if (configuration['host_checked']) {
          return 'dart2js_developer$suffix';
        } else {
          return 'dart2js$suffix';
        }
      case 'frog':
        return 'frog/bin/frog$suffix';
      default:
        throw "Unknown executable for: ${configuration['compiler']}";
    }
  }

  static String compilerName(Map configuration) {
    String suffix = executableSuffix(configuration['compiler']);
    switch (configuration['compiler']) {
      case 'dartc':
        return 'compiler/bin/dartc$suffix';
      case 'dart2js':
        if (configuration['host_checked']) {
          return 'dart2js_developer$suffix';
        } else {
          return 'dart2js$suffix';
        }
      case 'frog':
        return 'frog/bin/frog$suffix';
      default:
        throw "Unknown compiler for: ${configuration['compiler']}";
    }
  }

  static String dartShellFileName(Map configuration) {
    var name = configuration['dart'];
    if (name == '') {
      name = '${buildDir(configuration)}/${executableName(configuration)}';
    }
    ensureExists(name, configuration);
    return name;
  }

  static String d8FileName(Map configuration) {
    var suffix = executableSuffix('d8');
    var d8 = '${buildDir(configuration)}/d8$suffix';
    ensureExists(d8, configuration);
    return d8;
  }

  static void ensureExists(String filename, Map configuration) {
    if (!configuration['list'] && !(new File(filename).existsSync())) {
      throw "Executable '$filename' does not exist";
    }
  }

  static String compilerPath(Map configuration) {
    if (configuration['compiler'] == 'none') {
      return null;  // No separate compiler for dartium tests.
    }
    var name = configuration['frog'];
    if (name == '') {
      name = '${buildDir(configuration)}/${compilerName(configuration)}';
    }
    if (!(new File(name)).existsSync() && !configuration['list']) {
      throw "Executable '$name' does not exist";
    }
    return name;
  }

  static String outputDir(Map configuration) {
    var result = '';
    var system = configuration['system'];
    if (system == 'linux') {
      result = 'out/';
    } else if (system == 'macos') {
      result = 'xcodebuild/';
    }
    return result;
  }

  static String buildDir(Map configuration) {
    var result = outputDir(configuration);
    result += (configuration['mode'] == 'debug') ? 'Debug_' : 'Release_';
    result += configuration['arch'];
    return result;
  }

  static String dartDir() {
    String scriptPath = new Options().script.replaceAll('\\', '/');
    String toolsDir = scriptPath.substring(0, scriptPath.lastIndexOf('/'));
    return new File('$toolsDir/..').fullPathSync().replaceAll('\\', '/');
  }

  static List<String> standardOptions(Map configuration) {
    List args = ["--ignore-unrecognized-flags"];
    if (configuration["checked"]) {
      args.add('--enable_asserts');
      args.add("--enable_type_checks");
    }
    if (configuration["compiler"] == "dart2js") {
      args = [];
      args.add("--verbose");
      if (!isBrowserRuntime(configuration['runtime'])) {
        args.add("--allow-mock-compilation");
      }
    }
    return args;
  }

  static bool isBrowserRuntime(String runtime) =>
      const <String>['drt',
                     'dartium',
                     'ie',
                     'safari',
                     'opera',
                     'chrome',
                     'ff'].some((x) => x == runtime);
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
    String report = """Total: $total tests
 * $skipped tests will be skipped
 * $noCrash tests are expected to be flaky but not crash
 * $pass tests are expected to pass
 * $failOk tests are expected to fail that we won't fix
 * $fail tests are expected to fail that we should fix
 * $crash tests are expected to crash that we should fix
 * $timeout tests are allowed to timeout
""";
    print(report);
   }
}
