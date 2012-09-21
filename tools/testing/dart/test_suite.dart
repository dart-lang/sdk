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
   * to be listed each time.
   */
  void forEachTest(Function onTest, Map testCache, [Function onDone]);
}


// TODO(1030): remove once in the corelib.
bool Contains(element, collection) => collection.indexOf(element) >= 0;


void ccTestLister() {
  port.receive((String runnerPath, SendPort replyTo) {
    var p = Process.start(runnerPath, ["--list"]);
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
  final String testPrefix;
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
              List<String> this.statusFilePaths,
              [this.testPrefix = ''])
      : dartDir = TestUtils.dartDir().toNativePath() {
    runnerPath = '${TestUtils.buildDir(configuration)}/$runnerName';
  }

  void testNameHandler(String testName, ignore) {
    if (testName == "") {
      receiveTestName.close();
      doDone(true);
    } else {
      // Only run the tests that match the pattern. Use the name
      // "suiteName/testName" for cc tests.
      RegExp pattern = configuration['selectors'][suiteName];
      String constructedName = '$suiteName/$testPrefix$testName';
      if (!pattern.hasMatch(constructedName)) return;

      var expectations = testExpectations.expectations(
          '$testPrefix$testName');

      if (configuration["report"]) {
        SummaryReport.add(expectations);
      }

      if (expectations.contains(SKIP)) return;

      // The cc test runner takes options after the name of the test
      // to run.
      var args = [testName];
      args.addAll(TestUtils.standardOptions(configuration));

      doTest(new TestCase(constructedName,
                          [new Command(runnerPath, args)],
                          configuration,
                          completeHandler,
                          expectations));
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
        var port = spawnFunction(ccTestLister);
        port.send(runnerPath, receiveTestName.toSendPort());
        receiveTestName.receive(testNameHandler);
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
  Path filePath;
  Map optionsFromFile;
  bool isNegative;
  bool isNegativeIfChecked;
  bool hasFatalTypeErrors;
  bool hasRuntimeErrors;
  Set<String> multitestOutcome;

  TestInformation(this.filePath, this.optionsFromFile, this.isNegative,
                  this.isNegativeIfChecked, this.hasFatalTypeErrors,
                  this.hasRuntimeErrors, this.multitestOutcome) {
    Expect.isTrue(filePath.isAbsolute);
  }
}


/**
 * A standard [TestSuite] implementation that searches for tests in a
 * directory, and creates [TestCase]s that compile and/or run them.
 */
class StandardTestSuite implements TestSuite {
  Map configuration;
  String suiteName;
  Path suiteDir;
  List<String> statusFilePaths;
  Function doTest;
  Function doDone;
  int activeTestGenerators = 0;
  bool listingDone = false;
  TestExpectations testExpectations;
  List<TestInformation> cachedTests;
  final Path dartDir;
  Predicate<String> isTestFilePredicate;
  bool _listRecursive;

  StandardTestSuite(this.configuration,
                    this.suiteName,
                    Path suiteDirectory,
                    this.statusFilePaths,
                    [this.isTestFilePredicate,
                    bool recursive = false])
  : dartDir = TestUtils.dartDir(), _listRecursive = recursive,
    suiteDir = TestUtils.dartDir().join(suiteDirectory);

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
      Map configuration, Path directory) {
    final name = directory.filename;

    return new StandardTestSuite(configuration,
        name, directory,
        ['$directory/$name.status', '$directory/${name}_dart2js.status'],
        (filename) => filename.endsWith('_test.dart'),
        recursive: true);
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

  bool listRecursively() => _listRecursive;

  String shellPath() => TestUtils.dartShellFileName(configuration);

  List<String> additionalOptions(Path filePath) => [];

  void forEachTest(Function onTest, Map testCache, [Function onDone = null]) {
    // If DumpRenderTree/Dartium is required, and not yet updated,
    // wait for update.
    var updater = runtimeUpdater(configuration);
    if (updater !== null && !updater.updated) {
      Expect.isTrue(updater.isActive);
      updater.onUpdated.add(() {
        forEachTest(onTest, testCache, onDone);
      });
      return;
    }

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
          new Timer(0, enqueueCachedTests);
        }
      }
    }

    // Read test expectations from status files.
    testExpectations = new TestExpectations();
    for (var statusFilePath in statusFilePaths) {
      // [forDirectory] adds name_dart2js.status for all tests suites, use it if
      // it exists, but otherwise skip it and don't fail.
      if (statusFilePath.endsWith('_dart2js.status')) {
        File file = new File.fromPath(dartDir.append(statusFilePath));
        if (!file.existsSync()) {
          filesRead++;
          continue;
        }
      }
      ReadTestExpectationsInto(testExpectations,
                               dartDir.append(statusFilePath).toNativePath(),
                               configuration,
                               statusFileRead);
    }
  }

  void processDirectory() {
    Directory dir = new Directory.fromPath(suiteDir);
    dir.exists().then((exists) {
      if (!exists) {
        print('Directory containing tests not found: $suiteDir');
        directoryListingDone(false);
      } else {
        var lister = dir.list(recursive: listRecursively());
        lister.onFile = processFile;
        lister.onDone = directoryListingDone;
      }
    });
  }

  void enqueueTestCaseFromTestInformation(TestInformation info) {
    var filePath = info.filePath;
    var optionsFromFile = info.optionsFromFile;
    var isNegative = info.isNegative;

    // Look up expectations in status files using a test name generated
    // from the test file's path.
    String testName;

    if (optionsFromFile['isMultitest']) {
      // Multitests do not run on browsers.
      if (TestUtils.isBrowserRuntime(configuration['runtime'])) return;
      // Multitests are in [build directory]/generated_tests/... .
      // The test name will be '[test filename (no extension)]/[multitest key].
      String name = filePath.filenameWithoutExtension;
      int middle = name.lastIndexOf('_');
      testName = '${name.substring(0, middle)}/${name.substring(middle + 1)}';
    } else {
      // The test name is the relative path from the test suite directory to
      // the test, with the .dart extension removed.
      Expect.isTrue(filePath.toNativePath().startsWith(
                    suiteDir.toNativePath()));
      var testNamePath = filePath.relativeTo(suiteDir);
      Expect.isTrue(testNamePath.extension == 'dart');
      if (testNamePath.extension == 'dart') {
        testName = testNamePath.directoryPath.append(
            testNamePath.filenameWithoutExtension).toString();
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
        SummaryReport.add(expectations);
      }
    }
    if (expectations.contains(SKIP)) return;

    if (TestUtils.isBrowserRuntime(configuration['runtime'])) {
      bool isWrappingRequired = configuration['compiler'] != 'dart2js';
      if (configuration['runtime'] == 'ff' &&
          Platform.operatingSystem == 'windows') {
        // TODO(ahe): Investigate why this doesn't work on Windows.
        isWrappingRequired = true;
      }
      enqueueBrowserTest(info, testName, expectations, isWrappingRequired);
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

    var commonArguments = commonArgumentsFromFile(info.filePath,
                                                  info.optionsFromFile);

    List<List<String>> vmOptionsList = getVmOptions(info.optionsFromFile);
    Expect.isFalse(vmOptionsList.isEmpty(), "empty vmOptionsList");

    // Check for an "ExtraCommand" comment from the file, and generate
    // a command for it, if needed.
    var optionsFromFile = info.optionsFromFile;
    var commands = [];
    var command = optionsFromFile['extraCommand'];
    var args = optionsFromFile['extraCommandArgs'];
    if (command != null) {
      commands.add(new Command(command, args));
    }

    List _append(list1,list2) => []..addAll(list1)..addAll(list2);

    for (var vmOptions in vmOptionsList) {
      doTest(new TestCase('$suiteName/$testName',
                          _append(commands,
                              makeCommands(info, vmOptions, commonArguments)),
                          configuration,
                          completeHandler,
                          expectations,
                          isNegative,
                          info));
    }
  }

  List<Command> makeCommands(TestInformation info, var vmOptions, var args) {
    switch (configuration['compiler']) {
    case 'dart2js':
      args = new List.from(args);
      String tempDir = createOutputDirectory(info.filePath, '');
      args.add('--out=$tempDir/out.js');
      List<Command> commands = <Command>[new Command(shellPath(), args)];
      if (configuration['runtime'] == 'd8') {
        var d8 = TestUtils.d8FileName(configuration);
        commands.add(new Command(d8, ['$tempDir/out.js']));
      }
      return commands;

    case 'dart2dart':
      var compilerArguments = new List.from(args);
      var additionalFlags =
          configuration['additional-compiler-flags'].split(' ');
      for (final flag in additionalFlags) {
        if (flag.isEmpty()) continue;
        compilerArguments.add(flag);
      }
      compilerArguments.add('--output-type=dart');
      String tempDir = createOutputDirectory(info.filePath, '');
      compilerArguments.add('--out=$tempDir/out.dart');
      List<Command> commands =
          <Command>[new Command(shellPath(), compilerArguments)];
      if (configuration['runtime'] == 'vm') {
        // TODO(antonm): support checked.
        var vmArguments = new List.from(vmOptions);
        vmArguments.addAll([
            '--ignore-unrecognized-flags', '$tempDir/out.dart']);
        commands.add(new Command(
            TestUtils.vmFileName(configuration),
            vmArguments));
      } else {
        throw 'Unsupported runtime ${configuration["runtime"]} for dart2dart';
      }
      return commands;

    case 'none':
    case 'dartc':
      var arguments = new List.from(vmOptions);
      arguments.addAll(args);
      return <Command>[new Command(shellPath(), arguments)];

    default:
      throw 'Unknown compiler ${configuration["compiler"]}';
    }
  }

  Function makeTestCaseCreator(Map optionsFromFile) {
    return (Path filePath,
            bool isNegative,
            [bool isNegativeIfChecked = false,
             bool hasFatalTypeErrors = false,
             bool hasRuntimeErrors = false,
             Set<String> multitestOutcome = null]) {
      // Cache the test information for each test case.
      var info = new TestInformation(filePath,
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
    Path filePath = new Path.fromNative(filename);

    // Only run the tests that match the pattern.
    RegExp pattern = configuration['selectors'][suiteName];
    if (!pattern.hasMatch('$filePath')) return;
    if (filePath.filename.endsWith('test_config.dart')) return;

    var optionsFromFile = readOptionsFromFile(filePath);
    Function createTestCase = makeTestCaseCreator(optionsFromFile);

    if (optionsFromFile['isMultitest']) {
      testGeneratorStarted();
      DoMultitest(filePath,
                  TestUtils.buildDir(configuration),
                  suiteDir,
                  createTestCase,
                  testGeneratorDone);
    } else {
      createTestCase(filePath, optionsFromFile['isNegative']);
    }
  }

  /**
   * The [StandardTestSuite] has support for tests that
   * compile a test from Dart to JavaScript, and then run the resulting
   * JavaScript.  This function creates a working directory to hold the
   * JavaScript version of the test, and copies the appropriate framework
   * files to that directory.  It creates a [BrowserTestCase], which has
   * two sequential steps to be run by the [ProcessQueue] when the test is
   * executed: a compilation
   * step and an execution step, both with the appropriate executable and
   * arguments.
   */
  void enqueueBrowserTest(TestInformation info,
                          String testName,
                          Set<String> expectations,
                          bool isWrappingRequired) {
    Map optionsFromFile = info.optionsFromFile;
    Path filePath = info.filePath;
    String filename = filePath.toString();
    bool isWebTest = optionsFromFile['containsDomImport'];
    bool isLibraryDefinition = optionsFromFile['isLibraryDefinition'];
    if (isWrappingRequired
        && !isLibraryDefinition && optionsFromFile['containsSourceOrImport']) {
      print('Warning for $filename: Browser tests require #library '
            'in any file that uses #import, #source, or #resource');
    }

    final String compiler = configuration['compiler'];
    final String runtime = configuration['runtime'];

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
      final String tempDir = createOutputDirectory(info.filePath, optionsName);

      String dartWrapperFilename = '$tempDir/test.dart';
      String compiledDartWrapperFilename = '$tempDir/test.js';

      String htmlPath = '$tempDir/test.html';
      if (isWrappingRequired && !isWebTest) {
        // test.dart will import the dart test directly, if it is a library,
        // or indirectly through test_as_library.dart, if it is not.
        Path dartLibraryFilename = filePath;
        if (!isLibraryDefinition) {
          dartLibraryFilename = new Path('test_as_library.dart');
          File file = new File('$tempDir/$dartLibraryFilename');
          RandomAccessFile dartLibrary = file.openSync(FileMode.WRITE);
          dartLibrary.writeStringSync(wrapDartTestInLibrary(filePath));
          dartLibrary.closeSync();
        }

        File file = new File(dartWrapperFilename);
        RandomAccessFile dartWrapper = file.openSync(FileMode.WRITE);
        dartWrapper.writeStringSync(
            dartTestWrapper(dartDir, dartLibraryFilename));
        dartWrapper.closeSync();
      } else {
        dartWrapperFilename = filename;
        // TODO(whesse): Once test.py is retired, adjust the relative path in
        // the client/samples/dartcombat test to its css file, remove the
        // "../../" from this path, and move this out of the isWebTest guard.
        // Also remove getHtmlName, and just use test.html.
        // TODO(efortuna): this shortening of htmlFilename is a band-aid until
        // the above TODO gets fixed. Windows cannot have paths that are longer
        // than 260 characters, and without this hack, we were running past the
        // the limit.
        String htmlFilename = getHtmlName(filename);
        while ('$tempDir/../$htmlFilename'.length >= 260) {
          htmlFilename = htmlFilename.substring(htmlFilename.length~/2);
        }
        htmlPath = '$tempDir/../$htmlFilename';
      }
      final String scriptPath = (compiler == 'none') ?
          dartWrapperFilename : compiledDartWrapperFilename;
      // Create the HTML file for the test.
      RandomAccessFile htmlTest = new File(htmlPath).openSync(FileMode.WRITE);
      String filePrefix = '';
      if (Platform.operatingSystem == 'windows') {
        // Firefox on Windows does not like absolute file path names that start
        // with 'C:' adding 'file:///' solves the problem.
        filePrefix = 'file:///';
      }
      String content = null;
      Path dir = filePath.directoryPath;
      String nameNoExt = filePath.filenameWithoutExtension;
      Path pngPath = dir.append('$nameNoExt.png');
      Path txtPath = dir.append('$nameNoExt.txt');
      Path expectedOutput = null;
      if (new File.fromPath(pngPath).existsSync()) {
        expectedOutput = pngPath;
        content = getHtmlLayoutContents(scriptType, '$filePrefix$scriptPath');
      } else if (new File.fromPath(txtPath).existsSync()) {
        expectedOutput = txtPath;
        content = getHtmlLayoutContents(scriptType, '$filePrefix$scriptPath');
      } else {
        content = getHtmlContents(
          filename,
          '$filePrefix${dartDir.append("pkg/unittest/test_controller.js")}',
          '$filePrefix${dartDir.append("client/dart.js")}',
          scriptType,
          '$filePrefix$scriptPath');
      }
      htmlTest.writeStringSync(content);
      htmlTest.closeSync();

      // Construct the command(s) that compile all the inputs needed by the
      // browser test. For running Dart in DRT, this will be noop commands.
      List<Command> commands = [];
      if (compiler != 'none') {
        commands.add(_compileCommand(
            dartWrapperFilename, compiledDartWrapperFilename,
            compiler, tempDir, vmOptions));

        // some tests require compiling multiple input scripts.
        List<String> otherScripts = optionsFromFile['otherScripts'];
        for (String name in otherScripts) {
          Path namePath = new Path(name);
          Expect.equals(namePath.extension, 'dart');
          String baseName = namePath.filenameWithoutExtension;
          Path fromPath = filePath.directoryPath.join(namePath);
          commands.add(_compileCommand(
              fromPath.toNativePath(), '$tempDir/$baseName.js',
              compiler, tempDir, vmOptions));
        }
      }

      var extraCommand = optionsFromFile['extraCommand'];
      if (extraCommand != null) {
        var args = optionsFromFile['extraCommandArgs'];
        // As a special case, a command of "dart" should run with the same
        // dart executable that we are using.
        if (extraCommand == 'dart') {
          extraCommand = new Options().executable;
        }
        args= args.map((arg)=>arg.replaceAll(@"$dartDir", dartDir.toString()));
        commands.add(new Command(extraCommand, args));
      }

      // Construct the command that executes the browser test
      List<String> args;
      if (runtime == 'ie' || runtime == 'ff' || runtime == 'chrome' ||
          runtime == 'safari' || runtime == 'opera' || runtime == 'dartium') {
        args = [dartDir.append('tools/testing/run_selenium.py').toNativePath(),
            '--browser=$runtime',
            '--timeout=${configuration["timeout"] - 2}',
            '--out=$htmlPath'];
        if (runtime == 'dartium') {
          args.add('--executable=$dartiumFilename');
        }
      } else {
        args = [
            dartDir.append('tools/testing/drt-trampoline.py').toNativePath(),
            dumpRenderTreeFilename,
            '--no-timeout'
        ];
        if (runtime == 'drt' &&
            (compiler == 'none' || compiler == 'dart2dart')) {
          var dartFlags = ['--ignore-unrecognized-flags'];
          if (configuration["checked"]) {
            dartFlags.add('--enable_asserts');
            dartFlags.add("--enable_type_checks");
          }
          dartFlags.addAll(vmOptions);
          args.add('--dart-flags=${Strings.join(dartFlags, " ")}');
        }
        args.add(htmlPath);
        if (expectedOutput != null) {
          args.add('--out-expectation=${expectedOutput.toNativePath()}');
        }
      }
      commands.add(new Command('python', args));

      // Create BrowserTestCase and queue it.
      var testCase = new BrowserTestCase('$suiteName/$testName',
          commands, configuration, completeHandler, expectations,
          optionsFromFile['isNegative']);
      doTest(testCase);
    }
  }

  /** Helper to create a compilation command for a single input file. */
  Command _compileCommand(String inputFile, String outputFile,
      String compiler, String dir, var vmOptions) {
    String executable = TestUtils.compilerPath(configuration);
    List<String> args = TestUtils.standardOptions(configuration);
    switch (compiler) {
      case 'dart2js':
      case 'dart2dart':
        if (compiler == 'dart2dart') args.add('--out=$outputFile');
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

  /**
   * Create a directory for the generated test.  If a Dart language test
   * needs to be run in a browser, the Dart test needs to be embedded in
   * an HTML page, with a testing framework based on scripting and DOM events.
   * These scripts and pages are written to a generated_test directory
   * inside the build directory of the checkout.
   *
   * Those tests which are already HTML web applications (web tests), with
   * resources including CSS files and HTML files, need to be compiled into
   * a work directory where the relative URLS to the resources work.
   * We use a subdirectory of the build directory that is the same number
   * of levels down in the checkout as the original path of the web test.
   */
  String createOutputDirectory(Path testPath, String optionsName) {
    Path relative = testPath.relativeTo(TestUtils.dartDir());
    relative = relative.directoryPath.append(relative.filenameWithoutExtension);
    String testUniqueName = relative.toString().replaceAll('/', '_');
    if (!optionsName.isEmpty()) {
      testUniqueName = '$testUniqueName-$optionsName';
    }

    // Create '[build dir]/generated_tests/$compiler-$runtime/$testUniqueName',
    // including any intermediate directories that don't exist.
    var generatedTestPath = Strings.join(
        [TestUtils.buildDir(configuration),
         'generated_tests',
         "${configuration['compiler']}-${configuration['runtime']}",
         testUniqueName], '/');

    TestUtils.mkdirRecursive(new Path('.'), new Path(generatedTestPath));
    return new File(generatedTestPath).fullPathSync().replaceAll('\\', '/');
  }

  String get scriptType {
    switch (configuration['compiler']) {
      case 'none':
      case 'dart2dart':
        return 'application/dart';
      case 'dart2js':
      case 'dartc':
        return 'text/javascript';
      default:
        Expect.fail('Non-web runtime, so no scriptType for: '
                    '${configuration["compiler"]}');
        return null;
    }
  }

  bool get hasRuntime {
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
    var cleanFilename =  filename.replaceAll('/', '_')
                                 .replaceAll(':', '_')
                                 .replaceAll('\\', '_');

    return "$cleanFilename"
        "${configuration['compiler']}-${configuration['runtime']}.html";
  }

  String get dumpRenderTreeFilename {
    if (configuration['drt'] != '') {
      return configuration['drt'];
    }
    if (Platform.operatingSystem == 'macos') {
      return dartDir.append('/client/tests/drt/DumpRenderTree.app/Contents/'
                            'MacOS/DumpRenderTree').toNativePath();
    }
    return dartDir.append('client/tests/drt/DumpRenderTree').toNativePath();
  }

  String get dartiumFilename {
    if (configuration['dartium'] != '') {
      return configuration['dartium'];
    }
    if (Platform.operatingSystem == 'macos') {
      return dartDir.append('client/tests/dartium/Chromium.app/Contents/'
                            'MacOS/Chromium').toNativePath();
    }
    return dartDir.append('client/tests/dartium/chrome').toNativePath();
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

  List<String> commonArgumentsFromFile(Path filePath, Map optionsFromFile) {
    List args = TestUtils.standardOptions(configuration);
    args.addAll(additionalOptions(filePath));
    if (configuration['compiler'] == 'dartc') {
      args.add('--error_format');
      args.add('machine');
    }

    bool isMultitest = optionsFromFile["isMultitest"];
    List<String> dartOptions = optionsFromFile["dartOptions"];
    List<List<String>> vmOptionsList = getVmOptions(optionsFromFile);
    Expect.isTrue(!isMultitest || dartOptions == null);
    if (dartOptions == null) {
      args.add(filePath.toNativePath());
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

    return args;
  }

  /**
   * Special options for individual tests are currently specified in various
   * ways: with comments directly in test files, by using certain imports, or by
   * creating additional files in the test directories.
   *
   * Here is a list of options that are used by 'test.dart' today:
   *   - Flags can be passed to the vm or dartium process that runs the test by
   *   adding a comment to the test file:
   *
   *     // VMOptions=--flag1 --flag2
   *
   *   - Flags can be passed to the dart script that contains the test also
   *   using comments, as follows:
   *
   *     // DartOptions=--flag1 --flag2
   *
   *   - For tests that depend on compiling other files with dart2js (e.g.
   *   isolate tests that use multiple source scripts), you can specify
   *   additional files to compile using a comment too, as follows:
   *
   *     // OtherScripts=file1.dart file2.dart
   *
   *   - You can indicate whether a test is treated as a web-only test by
   *   using an explicit import to the dart:html library:
   *
   *     #import('dart:html');
   *
   *   Most tests are not web tests, but can (and will be) wrapped within
   *   another script file to test them also on browser environments (e.g.
   *   language and corelib tests are run this way). We deduce that if this
   *   import is specified, the test was intended to be a web test and no
   *   wrapping is necessary.
   *
   *   - You can convert DRT web-tests into layout-web-tests by specifying a
   *   test expectation file. An expectation file is located in the same
   *   location as the test, it has the same file name, except for the extension
   *   (which can be either .txt or .png).
   *
   *   When there are no expectation files, 'test.dart' assumes tests fail if
   *   the process return a non-zero exit code (in the case of web tests, we
   *   check for PASS/FAIL indications in the test output).
   *
   *   When there is an expectation file, tests are run differently: the test
   *   code is run to the end of the event loop and 'test.dart' takes a snapshot
   *   of what is rendered in the page at that moment. This snapshot is
   *   represented either in text form, if the expectation ends in .txt, or as
   *   an image, if the expectation ends in .png. 'test.dart' will compare the
   *   snapshot to the expectation file. When tests fail, 'test.dart' saves the
   *   new snapshot into a file so it can be visualized or copied over.
   *   Expectations can be recorded for the first time by creating an empty file
   *   with the right name (touch test_name_test.png), running the test, and
   *   executing the copy command printed by the test script.
   */
  Map readOptionsFromFile(Path filePath) {
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
    RegExp extraCommandRegExp =
        const RegExp(@"// ExtraCommand=(.*)", multiLine: true);
    RegExp extraArgsRegExp =
        const RegExp(@"// ExtraCommandArgs=(.*)", multiLine: true);

    // Read the entire file into a byte buffer and transform it to a
    // String. This will treat the file as ascii but the only parts
    // we are interested in will be ascii in any case.
    RandomAccessFile file = new File.fromPath(filePath).openSync(FileMode.READ);
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
            'More than one "// DartOptions=" line in test $filePath');
      }
      dartOptions = match[1].split(' ').filter((e) => e != '');
    }

    var match = extraCommandRegExp.firstMatch(contents);
    var extraCommand = (match != null) ? match.group(1) : null;
    match = extraArgsRegExp.firstMatch(contents);
    var extraCommandArgs = (match != null) ? match.group(1).split(' ') : [];

    matches = staticCleanRegExp.allMatches(contents);
    for (var match in matches) {
      if (isStaticClean) {
        throw new Exception(
            'More than one "// @static-clean=" line in test $filePath');
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
             "numCompileTimeAnnotations": numCompileTimeAnnotations,
             "extraCommand": extraCommand,
             "extraCommandArgs": extraCommandArgs};
  }

  List<List<String>> getVmOptions(Map optionsFromFile) {
    bool needsVmOptions = Contains(configuration['compiler'],
                                   const ['none', 'dart2dart', 'dartc']) &&
                          Contains(configuration['runtime'],
                                   const ['none', 'vm', 'drt', 'dartium']);
    if (!needsVmOptions) return [[]];
    return optionsFromFile['vmOptions'];
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
              new Path.fromNative(directoryPath),
              expectations);

  void activityStarted() { ++activityCount; }

  void activityCompleted() {
    if (--activityCount == 0) {
      directoryListingDone(true);
    }
  }

  String shellPath() => TestUtils.compilerPath(configuration);

  List<String> additionalOptions(Path filePath) {
    return ['--fatal-warnings', '--fatal-type-errors'];
  }

  void processDirectory() {
    // Enqueueing the directory listers is an activity.
    activityStarted();
    for (String testDir in _testDirs) {
      Directory dir = new Directory.fromPath(suiteDir.append(testDir));
      if (dir.existsSync()) {
        activityStarted();
        var lister = dir.list(recursive: listRecursively());
        lister.onFile = processFile;
        lister.onDone = (ignore) => activityCompleted();
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
      : dartDir = TestUtils.dartDir().toNativePath();

  bool isTestFile(String filename) => filename.endsWith("Tests.java") &&
      !filename.contains('com/google/dart/compiler/vm') &&
      !filename.contains('com/google/dart/corelib/SharedTests.java');

  void forEachTest(Function onTest,
                   Map testCacheIgnored,
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

    var lister = dir.list(recursive: true);
    lister.onFile = processFile;
    lister.onDone = createTest;
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
        '-Dcom.google.dart.corelib.SharedTests.test_py=$dartDir/tools/test.py',
        'org.junit.runner.JUnitCore'];
    args.addAll(testClasses);

    // Lengthen the timeout for JUnit tests.  It is normal for them
    // to run for a few minutes.
    Map updatedConfiguration = new Map();
    configuration.forEach((key, value) {
      updatedConfiguration[key] = value;
    });
    updatedConfiguration['timeout'] *= 3;
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
        ['$buildDir/analyzer/util/analyzer/dart_analyzer.jar',
         '$buildDir/analyzer/dart_analyzer_tests.jar',
         // Third party libraries.
         '$dartDir/third_party/args4j/2.0.12/args4j-2.0.12.jar',
         '$dartDir/third_party/guava/r09/guava-r09.jar',
         '$dartDir/third_party/rhino/1_7R3/js.jar',
         '$dartDir/third_party/hamcrest/v1_3/hamcrest-core-1.3.0RC2.jar',
         '$dartDir/third_party/hamcrest/v1_3/hamcrest-generator-1.3.0RC2.jar',
         '$dartDir/third_party/hamcrest/v1_3/hamcrest-integration-1.3.0RC2.jar',
         '$dartDir/third_party/hamcrest/v1_3/hamcrest-library-1.3.0RC2.jar',
         '$dartDir/third_party/junit/v4_8_2/junit.jar'],
        Platform.operatingSystem == 'windows'? ';': ':');  // Path separator.
  }
}


class TestUtils {
  /**
   * Creates a directory using a [relativePath] to an existing
   * [base] directory if that [relativePath] does not already exist.
   */
  static Directory mkdirRecursive(Path base, Path relativePath) {
    Directory dir = new Directory.fromPath(base);
    Expect.isTrue(dir.existsSync(),
                  "Expected ${dir} to already exist");
    var segments = relativePath.segments();
    for (String segment in segments) {
      base = base.append(segment);
      dir = new Directory.fromPath(base);
      if (!dir.existsSync()) {
          dir.createSync();
      }
      Expect.isTrue(dir.existsSync(), "Failed to create ${dir.path}");
    }
    return dir;
  }

  /**
   * Copy a [source] file to a new place.
   * Assumes that the directory for [dest] already exists.
   */
  static Future copyFile(Path source, Path dest) {
    var output = new File.fromPath(dest).openOutputStream();
    new File.fromPath(source).openInputStream().pipe(output);
    var completer = new Completer();
    output.onClosed = (){ completer.complete(null); };
    return completer.future;
  }

  static String executableSuffix(String executable) {
    if (Platform.operatingSystem == 'windows') {
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
        return 'analyzer/bin/dart_analyzer$suffix';
      case 'dart2js':
      case 'dart2dart':
        var prefix = '';
        if (configuration['use_sdk']) {
          prefix = 'dart-sdk/bin/';
        }
        if (configuration['host_checked']) {
          // The script dart2js_developer is not in the SDK.
          return 'dart2js_developer$suffix';
        } else {
          return '${prefix}dart2js$suffix';
        }
      default:
        throw "Unknown executable for: ${configuration['compiler']}";
    }
  }

  static String compilerName(Map configuration) {
    String suffix = executableSuffix(configuration['compiler']);
    switch (configuration['compiler']) {
      case 'dartc':
      case 'dart2js':
      case 'dart2dart':
        return executableName(configuration);
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

  static String vmFileName(Map configuration) {
    var suffix = executableSuffix('vm');
    var vm = '${buildDir(configuration)}/dart$suffix';
    ensureExists(vm, configuration);
    return vm;
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
    var name = '${buildDir(configuration)}/${compilerName(configuration)}';
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
    } else if (system == 'windows') {
      result = 'build/';
    }
    return result;
  }

  static String buildDir(Map configuration) {
    String mode = (configuration['mode'] == 'debug') ? 'Debug' : 'Release';
    String arch = configuration['arch'].toUpperCase();
    return "${outputDir(configuration)}$mode$arch";
 }

  static Path dartDir() {
    File scriptFile = new File(new Options().script);
    Path scriptPath = new Path.fromNative(scriptFile.fullPathSync());
    return scriptPath.directoryPath.directoryPath;
  }

  static List<String> standardOptions(Map configuration) {
    List args = ["--ignore-unrecognized-flags"];
    if (configuration["checked"]) {
      args.add('--enable_asserts');
      args.add("--enable_type_checks");
    }
    String compiler = configuration["compiler"];
    if (compiler == "dart2js" || compiler == "dart2dart") {
      args = [];
      if (configuration["checked"]) {
        args.add('--enable-checked-mode');
      }
      // args.add("--verbose");
      if (!isBrowserRuntime(configuration['runtime'])) {
        args.add("--allow-mock-compilation");
      }
    }
    return args;
  }

  static bool isBrowserRuntime(String runtime) => Contains(
      runtime,
      const <String>['drt',
                     'dartium',
                     'ie',
                     'safari',
                     'opera',
                     'chrome',
                     'ff']);
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
