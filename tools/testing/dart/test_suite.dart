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
library test_suite;

import "dart:async";
import "dart:io";
import "dart:isolate";
import "dart:uri";
import "drt_updater.dart";
import "multitest.dart";
import "status_file_parser.dart";
import "test_runner.dart";
import "utils.dart";
import "http_server.dart" show PREFIX_BUILDDIR, PREFIX_DARTDIR;

part "browser_test.dart";


// TODO(rnystrom): Add to dart:core?
/**
 * A simple function that tests [arg] and returns `true` or `false`.
 */
typedef bool Predicate<T>(T arg);

typedef void CreateTest(Path filePath,
                        bool hasCompileError,
                        bool hasRuntimeError,
                        {bool isNegativeIfChecked,
                         bool hasFatalTypeErrors,
                         Set<String> multitestOutcome});

typedef void VoidFunction();

/**
 * Calls [function] asynchronously. Returns a future that completes with the
 * result of the function. If the function is `null`, returns a future that
 * completes immediately with `null`.
 */
Future asynchronously(function()) {
  if (function == null) return new Future.immediate(null);

  var completer = new Completer();
  Timer.run(() => completer.complete(function()));

  return completer.future;
}

/** A completer that waits until all added [Future]s complete. */
// TODO(rnystrom): Copied from web_components. Remove from here when it gets
// added to dart:core. (See #6626.)
class FutureGroup {
  const _FINISHED = -1;
  int _pending = 0;
  Completer<List> _completer = new Completer<List>();
  final List<Future> futures = <Future>[];
  bool wasCompleted = false;

  /**
   * Wait for [task] to complete (assuming this barrier has not already been
   * marked as completed, otherwise you'll get an exception indicating that a
   * future has already been completed).
   */
  void add(Future task) {
    if (_pending == _FINISHED) {
      throw new Exception("FutureFutureAlreadyCompleteException");
    }
    _pending++;
    var handledTaskFuture = task.catchError((e) {
      if (!wasCompleted) {
        _completer.completeError(e);
        wasCompleted = true;
      }
    }).then((_) {
      _pending--;
      if (_pending == 0) {
        _pending = _FINISHED;
        if (!wasCompleted) {
          _completer.complete(futures);
          wasCompleted = true;
        }
      }
    });
    futures.add(handledTaskFuture);
  }

  Future<List> get future => _completer.future;
}

/**
 * A TestSuite represents a collection of tests.  It creates a [TestCase]
 * object for each test to be run, and passes the test cases to a callback.
 *
 * Most TestSuites represent a directory or directory tree containing tests,
 * and a status file containing the expected results when these tests are run.
 */
abstract class TestSuite {
  final Map configuration;
  final String suiteName;

  TestSuite(this.configuration, this.suiteName);

  /**
   * Whether or not binaries should be found in the root build directory or
   * in the built SDK.
   */
  bool get useSdk {
    // The pub suite always uses the SDK.
    // TODO(rnystrom): Eventually, all test suites should run out of the SDK
    // and this check should go away.
    if (suiteName == 'pub') return true;

    return configuration['use_sdk'];
  }

  /**
   * The output directory for this suite's configuration.
   */
  String get buildDir => TestUtils.buildDir(configuration);

  /**
   * The path to the compiler for this suite's configuration. Returns `null` if
   * no compiler should be used.
   */
  String get compilerPath {
    if (configuration['compiler'] == 'none') {
      return null;  // No separate compiler for dartium tests.
    }
    var name;
    switch (configuration['compiler']) {
      case 'dartc':
      case 'dartanalyzer':
        name = executablePath;
        break;
      case 'dart2js':
      case 'dart2dart':
        var prefix = 'sdk/bin/';
        String suffix = getExecutableSuffix(configuration['compiler']);
        if (configuration['host_checked']) {
          // The script dart2js_developer is not included in the
          // shipped SDK, that is the script is not installed in
          // "$buildDir/dart-sdk/bin/"
          name = '$prefix/dart2js_developer$suffix';
        } else {
          if (configuration['use_sdk']) {
            prefix = '$buildDir/dart-sdk/bin/';
          }
          name = '${prefix}dart2js$suffix';
        }
        break;
      default:
        throw "Unknown compiler for: ${configuration['compiler']}";
    }
    if (!(new File(name)).existsSync() && !configuration['list']) {
      throw "Executable '$name' does not exist";
    }
    return name;
  }

  /**
   * The path to the executable used to run this suite's tests.
   */
  String get executablePath {
    var suffix = getExecutableSuffix(configuration['compiler']);
    switch (configuration['compiler']) {
      case 'none':
        if (useSdk) {
          return '$buildDir/dart-sdk/bin/dart$suffix';
        }
        return '$buildDir/dart$suffix';
      case 'dartc':
        return '$buildDir/analyzer/bin/dart_analyzer$suffix';
      case 'dartanalyzer':
        return 'sdk/bin/dartanalyzer_developer$suffix';
      default:
        throw "Unknown executable for: ${configuration['compiler']}";
    }
  }

  /**
   * The file name of the d8 executable.
   */
  String get d8FileName {
    var suffix = getExecutableSuffix('d8');
    var d8 = '$buildDir/d8$suffix';
    TestUtils.ensureExists(d8, configuration);
    return d8;
  }

  String get dartShellFileName {
    var name = configuration['dart'];
    if (name == '') {
      name = executablePath;
    }

    TestUtils.ensureExists(name, configuration);
    return name;
  }

  String get jsShellFileName {
    var executableSuffix = getExecutableSuffix('jsshell');
    var executable = 'jsshell$executableSuffix';
    var jsshellDir = '${TestUtils.dartDir()}/tools/testing/bin';
    return '$jsshellDir/$executable';
  }

  /**
   * The file name of the Dart VM executable.
   */
  String get vmFileName {
    var suffix = getExecutableSuffix('vm');
    var vm = '$buildDir/dart$suffix';
    TestUtils.ensureExists(vm, configuration);
    return vm;
  }

  /**
   * The file extension (if any) that should be added to the given executable
   * name for the current platform.
   */
  String getExecutableSuffix(String executable) {
    if (Platform.operatingSystem == 'windows') {
      if (executable == 'd8' || executable == 'vm' || executable == 'none') {
        return '.exe';
      } else {
        return '.bat';
      }
    }
    return '';
  }

  /**
   * Call the callback function onTest with a [TestCase] argument for each
   * test in the suite.  When all tests have been processed, call [onDone].
   *
   * The [testCache] argument provides a persistent store that can be used to
   * cache information about the test suite, so that directories do not need
   * to be listed each time.
   */
  void forEachTest(TestCaseEvent onTest, Map testCache, [VoidFunction onDone]);
}


void ccTestLister() {
  port.receive((String runnerPath, SendPort replyTo) {
    Future processFuture = Process.start(runnerPath, ["--list"]);
    processFuture.then((Process p) {
      // Drain stderr to not leak resources.
      p.stderr.listen((_) { });
      Stream<String> stdoutStream =
          p.stdout.transform(new StringDecoder())
                  .transform(new LineTransformer());
      var streamDone = false;
      var processExited = false;
      checkDone() {
        if (streamDone && processExited) {
          replyTo.send("");
        }
      }
      stdoutStream.listen((String line) {
        replyTo.send(line);
      },
      onDone: () {
        streamDone = true;
        checkDone();
      });

      p.exitCode.then((code) {
        if (code < 0) {
          print("Failed to list tests: $runnerPath --list");
          replyTo.send("");
        } else {
          processExited = true;
          checkDone();
        }
      });
      port.close();
    }).catchError((e) {
      print("Failed to list tests: $runnerPath --list");
      replyTo.send("");
      return true;
    });
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
class CCTestSuite extends TestSuite {
  final String testPrefix;
  String runnerPath;
  final String dartDir;
  List<String> statusFilePaths;
  TestCaseEvent doTest;
  VoidFunction doDone;
  ReceivePort receiveTestName;
  TestExpectations testExpectations;

  CCTestSuite(Map configuration,
              String suiteName,
              String runnerName,
              List<String> this.statusFilePaths,
              {this.testPrefix: ''})
      : super(configuration, suiteName),
        dartDir = TestUtils.dartDir().toNativePath() {
    runnerPath = '$buildDir/$runnerName';
  }

  void testNameHandler(String testName, ignore) {
    if (testName == "") {
      receiveTestName.close();

      if (doDone != null) doDone();
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

      var args = TestUtils.standardOptions(configuration);
      args.add(testName);

      doTest(new TestCase(constructedName,
                          [new Command(runnerPath, args)],
                          configuration,
                          completeHandler,
                          expectations));
    }
  }

  void forEachTest(TestCaseEvent onTest, Map testCache, [VoidFunction onDone]) {
    doTest = onTest;
    doDone = onDone;

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
  bool hasCompileError;
  bool hasRuntimeError;
  bool isNegativeIfChecked;
  bool hasFatalTypeErrors;
  Set<String> multitestOutcome;

  TestInformation(this.filePath, this.optionsFromFile,
                  this.hasCompileError, this.hasRuntimeError,
                  this.isNegativeIfChecked, this.hasFatalTypeErrors,
                  this.multitestOutcome) {
    assert(filePath.isAbsolute);
  }
}

/**
 * A standard [TestSuite] implementation that searches for tests in a
 * directory, and creates [TestCase]s that compile and/or run them.
 */
class StandardTestSuite extends TestSuite {
  final Path suiteDir;
  final List<String> statusFilePaths;
  TestCaseEvent doTest;
  TestExpectations testExpectations;
  List<TestInformation> cachedTests;
  final Path dartDir;
  Predicate<String> isTestFilePredicate;
  final bool listRecursively;

  static final RegExp multiTestRegExp = new RegExp(r"/// [0-9][0-9]:(.*)");

  StandardTestSuite(Map configuration,
                    String suiteName,
                    Path suiteDirectory,
                    this.statusFilePaths,
                    {this.isTestFilePredicate,
                    bool recursive: false})
  : super(configuration, suiteName),
    dartDir = TestUtils.dartDir(),
    listRecursively = recursive,
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
   *
   * The [StandardTestSuite] also optionally takes a list of servers that have
   * been started up by the test harness, to be used by browser tests.
   */
  factory StandardTestSuite.forDirectory(
      Map configuration, Path directory) {
    final name = directory.filename;

    return new StandardTestSuite(configuration,
        name, directory,
        ['$directory/$name.status', '$directory/${name}_dart2js.status'],
        isTestFilePredicate: (filename) => filename.endsWith('_test.dart'),
        recursive: true);
  }

  Collection<Uri> get dart2JsBootstrapDependencies {
    if (!useSdk) return [];

    var snapshotPath = TestUtils.absolutePath(new Path(buildDir).join(
        new Path('dart-sdk/bin/snapshots/'
                 'utils_wrapper.dart.snapshot'))).toString();
    return [new Uri.fromComponents(scheme: 'file', path: snapshotPath)];
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

  List<String> additionalOptions(Path filePath) => [];

  void forEachTest(TestCaseEvent onTest, Map testCache, [VoidFunction onDone]) {
    updateDartium().then((_) {
      doTest = onTest;

      return readExpectations();
    }).then((expectations) {
      testExpectations = expectations;

      // Checked if we have already found and generated the tests for
      // this suite.
      if (!testCache.containsKey(suiteName)) {
        cachedTests = testCache[suiteName] = [];
        return enqueueTests();
      } else {
        // We rely on enqueueing completing asynchronously.
        return asynchronously(() {
          for (var info in testCache[suiteName]) {
            enqueueTestCaseFromTestInformation(info);
          }
        });
      }
    }).then((_) {
      if (onDone != null) onDone();
    });
  }

  /**
   * If DumpRenderTree/Dartium is required, and not yet updated, waits for
   * the update then completes. Otherwise completes immediately.
   */
  Future updateDartium() {
    var completer = new Completer();
    var updater = runtimeUpdater(configuration);
    if (updater == null || updater.updated) {
      return new Future.immediate(null);
    }

    assert(updater.isActive);
    updater.onUpdated.add(() => completer.complete(null));

    return completer.future;
  }

  /**
   * Reads the status files and completes with the parsed expectations.
   */
  Future<TestExpectations> readExpectations() {
    var completer = new Completer();
    var expectations = new TestExpectations();

    var filesRead = 0;
    void statusFileRead() {
      filesRead++;
      if (filesRead == statusFilePaths.length) {
        completer.complete(expectations);
      }
    }

    for (var statusFilePath in statusFilePaths) {
      // [forDirectory] adds name_dart2js.status for all tests suites. Use it
      // if it exists, but otherwise skip it and don't fail.
      if (statusFilePath.endsWith('_dart2js.status')) {
        var file = new File.fromPath(dartDir.append(statusFilePath));
        if (!file.existsSync()) {
          filesRead++;
          continue;
        }
      }

      ReadTestExpectationsInto(expectations,
                               dartDir.append(statusFilePath).toNativePath(),
                               configuration, statusFileRead);
    }

    return completer.future;
  }

  Future enqueueTests() {
    Directory dir = new Directory.fromPath(suiteDir);
    return dir.exists().then((exists) {
      if (!exists) {
        print('Directory containing tests missing: ${suiteDir.toNativePath()}');
        return new Future.immediate(null);
      } else {
        var group = new FutureGroup();
        enqueueDirectory(dir, group);
        return group.future;
      }
    });
  }

  void enqueueDirectory(Directory dir, FutureGroup group) {
    var listCompleter = new Completer();
    group.add(listCompleter.future);

    var lister = dir.list(recursive: listRecursively)
        .listen((FileSystemEntity fse) {
          if (fse is File) enqueueFile(fse.path, group);
        },
        onDone: listCompleter.complete);
  }

  void enqueueFile(String filename, FutureGroup group) {
    if (!isTestFile(filename)) return;
    Path filePath = new Path(filename);

    // Only run the tests that match the pattern.
    RegExp pattern = configuration['selectors'][suiteName];
    if (!pattern.hasMatch('$filePath')) return;
    if (filePath.filename.endsWith('test_config.dart')) return;

    var optionsFromFile = readOptionsFromFile(filePath);
    CreateTest createTestCase = makeTestCaseCreator(optionsFromFile);

    if (optionsFromFile['isMultitest']) {
      group.add(doMultitest(filePath, buildDir, suiteDir, createTestCase));
    } else {
      createTestCase(filePath,
                     optionsFromFile['hasCompileError'],
                     optionsFromFile['hasRuntimeError']);
    }
  }

  void enqueueTestCaseFromTestInformation(TestInformation info) {
    var filePath = info.filePath;
    var optionsFromFile = info.optionsFromFile;
    var isNegative = info.hasCompileError;
    if (info.hasRuntimeError && hasRuntime) {
      isNegative = true;
    }

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
      assert(filePath.toNativePath().startsWith(
                    suiteDir.toNativePath()));
      var testNamePath = filePath.relativeTo(suiteDir);
      assert(testNamePath.extension == 'dart');
      if (testNamePath.extension == 'dart') {
        testName = testNamePath.directoryPath.append(
            testNamePath.filenameWithoutExtension).toString();
      }
    }
    int shards = configuration['shards'];
    if (shards > 1) {
      int shard = configuration['shard'];
      if (testName.hashCode % shards != shard - 1) {
        return;
      }
    }

    Set<String> expectations = testExpectations.expectations(testName);
    if (info.hasCompileError &&
        TestUtils.isBrowserRuntime(configuration['runtime']) &&
        configuration['report']) {
      SummaryReport.addCompileErrorSkipTest();
      return;
    }
    if (configuration['report']) {
      // Tests with multiple VMOptions are counted more than once.
      for (var dummy in getVmOptions(optionsFromFile)) {
        SummaryReport.add(expectations);
      }
    }
    if (expectations.contains(SKIP)) return;

    if (configuration['compiler'] != 'none' && info.hasCompileError) {
      // If a compile-time error is expected, and we're testing a
      // compiler, we never need to attempt to run the program (in a
      // browser or otherwise).
      enqueueStandardTest(info, testName, expectations);
    } else if (TestUtils.isBrowserRuntime(configuration['runtime'])) {
      bool isWrappingRequired = configuration['compiler'] != 'dart2js';
      if (info.optionsFromFile['isMultiHtmlTest']) {
        // A browser multi-test has multiple expectations for one test file.
        // Find all the different sub-test expecations for one entire test file.
        List<String> subtestNames = info.optionsFromFile['subtestNames'];
        Map<String, Set<String>> multiHtmlTestExpectations = {};
        for (String name in subtestNames) {
          String fullTestName = '$testName/$name';
          multiHtmlTestExpectations[fullTestName] =
              testExpectations.expectations(fullTestName);
        }
        enqueueBrowserTest(info, testName, multiHtmlTestExpectations,
            isWrappingRequired);
      } else {
        enqueueBrowserTest(info, testName, expectations, isWrappingRequired);
      }
    } else {
      enqueueStandardTest(info, testName, expectations);
    }
  }

  void enqueueStandardTest(TestInformation info,
                           String testName,
                           Set<String> expectations) {
    bool isNegative = info.hasCompileError ||
        (configuration['checked'] && info.isNegativeIfChecked);
    if (info.hasRuntimeError && hasRuntime) {
      isNegative = true;
    }

    if (configuration['analyzer']) {
      // An analyzer can detect static type warnings by the
      // format of the error line
      if (info.hasFatalTypeErrors) {
        isNegative = true;
      }
    }

    var commonArguments = commonArgumentsFromFile(info.filePath,
                                                  info.optionsFromFile);

    List<List<String>> vmOptionsList = getVmOptions(info.optionsFromFile);
    assert(!vmOptionsList.isEmpty);

    for (var vmOptions in vmOptionsList) {
      doTest(new TestCase('$suiteName/$testName',
                          makeCommands(info, vmOptions, commonArguments),
                          configuration,
                          completeHandler,
                          expectations,
                          isNegative: isNegative,
                          info: info));
    }
  }

  List<Command> makeCommands(TestInformation info, var vmOptions, var args) {
    switch (configuration['compiler']) {
    case 'dart2js':
      args = new List.from(args);
      String tempDir = createOutputDirectory(info.filePath, '');
      args.add('--out=$tempDir/out.js');

       List<Command> commands =
           <Command>[new CompilationCommand("$tempDir/out.js",
                                            !useSdk,
                                            dart2JsBootstrapDependencies,
                                            compilerPath,
                                            args)];
      if (info.hasCompileError) {
        // Do not attempt to run the compiled result. A compilation
        // error should be reported by the compilation command.
      } else if (configuration['runtime'] == 'd8') {
        commands.add(new Command(d8FileName, ['$tempDir/out.js']));
      } else if (configuration['runtime'] == 'jsshell') {
        commands.add(new Command(jsShellFileName, ['$tempDir/out.js']));
      }
      return commands;

    case 'dart2dart':
      args = new List.from(args);
      args.add('--output-type=dart');
      String tempDir = createOutputDirectory(info.filePath, '');
      args.add('--out=$tempDir/out.dart');

      List<Command> commands =
          <Command>[new CompilationCommand("$tempDir/out.dart",
                                           !useSdk,
                                           dart2JsBootstrapDependencies,
                                           compilerPath,
                                           args)];
      if (info.hasCompileError) {
        // Do not attempt to run the compiled result. A compilation
        // error should be reported by the compilation command.
      } else if (configuration['runtime'] == 'vm') {
        // TODO(antonm): support checked.
        var vmArguments = new List.from(vmOptions);
        vmArguments.addAll([
            '--ignore-unrecognized-flags', '$tempDir/out.dart']);
        commands.add(new Command(vmFileName, vmArguments));
      } else {
        throw 'Unsupported runtime ${configuration["runtime"]} for dart2dart';
      }
      return commands;

    case 'none':
    case 'dartc':
    case 'dartanalyzer':
      var arguments = new List.from(vmOptions);
      arguments.addAll(args);
      return <Command>[new Command(dartShellFileName, arguments)];

    default:
      throw 'Unknown compiler ${configuration["compiler"]}';
    }
  }

  CreateTest makeTestCaseCreator(Map optionsFromFile) {
    return (Path filePath,
            bool hasCompileError,
            bool hasRuntimeError,
            {bool isNegativeIfChecked: false,
             bool hasFatalTypeErrors: false,
             Set<String> multitestOutcome: null}) {
      // Cache the test information for each test case.
      var info = new TestInformation(filePath,
                                     optionsFromFile,
                                     hasCompileError,
                                     hasRuntimeError,
                                     isNegativeIfChecked,
                                     hasFatalTypeErrors,
                                     multitestOutcome);
      cachedTests.add(info);
      enqueueTestCaseFromTestInformation(info);
    };
  }


  /**
   * _createUrlPathFromFile takes a [file], which is either located in the dart
   * or in the build directory, and will return a String representing
   * the relative path to either the dart or the build directory.
   * Thus, the returned [String] will be the path component of the URL
   * corresponding to [file] (the http server serves files relative to the
   * dart/build directories).
   */
  String _createUrlPathFromFile(Path file) {
    file = TestUtils.absolutePath(file);

    var relativeBuildDir = new Path(TestUtils.buildDir(configuration));
    var buildDir = TestUtils.absolutePath(relativeBuildDir);
    var dartDir = TestUtils.absolutePath(TestUtils.dartDir());

    var fileString = file.toString();
    if (fileString.startsWith(buildDir.toString())) {
      var fileRelativeToBuildDir = file.relativeTo(buildDir);
      return "/$PREFIX_BUILDDIR/$fileRelativeToBuildDir";
    } else if (fileString.startsWith(dartDir.toString())) {
      var fileRelativeToDartDir = file.relativeTo(dartDir);
      return "/$PREFIX_DARTDIR/$fileRelativeToDartDir";
    }
    // Unreachable
    print("Cannot create URL for path $file. Not in build or dart directory.");
    exit(1);
  }

  String _getUriForBrowserTest(TestInformation info,
                            String pathComponent,
                            subtestNames,
                            subtestIndex) {
    // Note: If we run test.py with the "--list" option, no http servers
    // will be started. So we use PORT/CROSS_ORIGIN_PORT instead of real ports.
    var serverPort = "PORT";
    var crossOriginPort = "CROSS_ORIGIN_PORT";
    if (!configuration['list']) {
      assert(configuration.containsKey('_servers_'));
      serverPort = configuration['_servers_'].port;
      crossOriginPort = configuration['_servers_'].crossOriginPort;
    }

    var url= 'http://127.0.0.1:$serverPort$pathComponent'
        '?crossOriginPort=$crossOriginPort';
    if (info.optionsFromFile['isMultiHtmlTest'] && subtestNames.length > 0) {
      url= '${url}&group=${subtestNames[subtestIndex]}';
    }
    return url;
  }

  void _createWrapperFile(String dartWrapperFilename, dartLibraryFilename) {
    File file = new File(dartWrapperFilename);
    RandomAccessFile dartWrapper = file.openSync(FileMode.WRITE);

    var usePackageImport = dartLibraryFilename.segments().contains("pkg");
    var libraryPathComponent = _createUrlPathFromFile(dartLibraryFilename);
    dartWrapper.writeStringSync(dartTestWrapper(usePackageImport,
                                                libraryPathComponent));
    dartWrapper.closeSync();
  }

  /**
   * The [StandardTestSuite] has support for tests that
   * compile a test from Dart to JavaScript, and then run the resulting
   * JavaScript.  This function creates a working directory to hold the
   * JavaScript version of the test, and copies the appropriate framework
   * files to that directory.  It creates a [BrowserTestCase], which has
   * two sequential steps to be run by the [ProcessQueue] when the test is
   * executed: a compilation step and an execution step, both with the
   * appropriate executable and arguments. The [expectations] object can be
   * either a Set<String> if the test is a regular test, or a Map<String
   * subTestName, Set<String>> if we are running a browser multi-test (one
   * compilation and many browser runs).
   */
  void enqueueBrowserTest(TestInformation info,
                          String testName,
                          Object expectations,
                          bool isWrappingRequired) {
    // TODO(kustermann/ricow): This method should be refactored.
    Map optionsFromFile = info.optionsFromFile;
    Path filePath = info.filePath;
    String filename = filePath.toString();
    bool isWebTest = optionsFromFile['containsDomImport'];

    final String compiler = configuration['compiler'];
    final String runtime = configuration['runtime'];

    for (var vmOptions in getVmOptions(optionsFromFile)) {
      // Create a unique temporary directory for each set of vmOptions.
      // TODO(dart:429): Replace separate replaceAlls with a RegExp when
      // replaceAll(RegExp, String) is implemented.
      String optionsName = '';
      if (getVmOptions(optionsFromFile).length > 1) {
          optionsName = vmOptions.join('-').replaceAll('-','')
                                           .replaceAll('=','')
                                           .replaceAll('/','');
      }
      final String tempDir = createOutputDirectory(info.filePath, optionsName);

      String dartWrapperFilename = '$tempDir/test.dart';
      String compiledDartWrapperFilename = '$tempDir/test.js';

      String htmlPath = '$tempDir/test.html';
      if (isWrappingRequired && !isWebTest) {
        // test.dart will import the dart test.
        _createWrapperFile(dartWrapperFilename, filePath);
      } else {
        dartWrapperFilename = filename;
      }
      String scriptPath = (compiler == 'none') ?
          dartWrapperFilename : compiledDartWrapperFilename;
      scriptPath = _createUrlPathFromFile(new Path(scriptPath));

      // Create the HTML file for the test.
      RandomAccessFile htmlTest = new File(htmlPath).openSync(FileMode.WRITE);
      String content = null;
      Path dir = filePath.directoryPath;
      String nameNoExt = filePath.filenameWithoutExtension;
      Path pngPath = dir.append('$nameNoExt.png');
      Path txtPath = dir.append('$nameNoExt.txt');
      Path expectedOutput = null;
      if (new File.fromPath(pngPath).existsSync()) {
        expectedOutput = pngPath;
        content = getHtmlLayoutContents(scriptType, new Path("$scriptPath"));
      } else if (new File.fromPath(txtPath).existsSync()) {
        expectedOutput = txtPath;
        content = getHtmlLayoutContents(scriptType, new Path("$scriptPath"));
      } else {
        content = getHtmlContents(filename, scriptType,
            new Path("$scriptPath"));
      }
      htmlTest.writeStringSync(content);
      htmlTest.closeSync();

      // Construct the command(s) that compile all the inputs needed by the
      // browser test. For running Dart in DRT, this will be noop commands.
      List<Command> commands = [];
      if (compiler != 'none') {
        commands.add(_compileCommand(
            dartWrapperFilename, compiledDartWrapperFilename,
            compiler, tempDir, vmOptions, optionsFromFile));
      }

      // some tests require compiling multiple input scripts.
      List<String> otherScripts = optionsFromFile['otherScripts'];
      for (String name in otherScripts) {
        Path namePath = new Path(name);
        String baseName = namePath.filenameWithoutExtension;
        Path fromPath = filePath.directoryPath.join(namePath);
        if (compiler != 'none') {
          assert(namePath.extension == 'dart');
          commands.add(_compileCommand(
              fromPath.toNativePath(), '$tempDir/$baseName.js',
              compiler, tempDir, vmOptions, optionsFromFile));
        }
        if (compiler == 'none') {
          // For the tests that require multiple input scripts but are not
          // compiled, move the input scripts over with the script so they can
          // be accessed.
          String result = new File.fromPath(fromPath).readAsStringSync();
          new File('$tempDir/$baseName.dart').writeAsStringSync(result);
        }
      }

      // Variables for browser multi-tests.
      List<String> subtestNames = info.optionsFromFile['subtestNames'];
      TestCase multitestParentTest;
      int subtestIndex = 0;
      // Construct the command that executes the browser test
      do {
        List<Command> commandSet = new List<Command>.from(commands);
        if (subtestIndex != 0) {
          // NOTE: The first time we enter this loop, all the compilation
          // commands will be executed. On subsequent loop iterations, we
          // don't need to do any compilations. Thus we set "commandSet = []".
          commandSet = [];
        }

        var htmlPath_subtest = _createUrlPathFromFile(new Path(htmlPath));
        var fullHtmlPath = _getUriForBrowserTest(info, htmlPath_subtest,
                                                 subtestNames, subtestIndex);

        List<String> args = <String>[];
        if (TestUtils.usesWebDriver(runtime)) {
          args = [
              dartDir.append('tools/testing/run_selenium.py').toNativePath(),
              '--browser=$runtime',
              '--timeout=${configuration["timeout"]~/2}',
              '--out=$fullHtmlPath'];
          if (runtime == 'dartium') {
            args.add('--executable=$dartiumFilename');
          }
          if (subtestIndex != 0) {
            args.add('--force-refresh');
          }
          commandSet.add(new Command('python', args));
        } else {
          if (runtime != "drt") {
            print("Unknown runtime $runtime");
            exit(1);
          }

          var dartFlags = [];
          var dumpRenderTreeOptions = [];

          dumpRenderTreeOptions.add('--no-timeout');

          if (compiler == 'none' || compiler == 'dart2dart') {
            dartFlags.add('--ignore-unrecognized-flags');
            if (configuration["checked"]) {
              dartFlags.add('--enable_asserts');
              dartFlags.add("--enable_type_checks");
            }
            dartFlags.addAll(vmOptions);
          }

          if (expectedOutput != null) {
            if (expectedOutput.toNativePath().endsWith('.png')) {
              // pixel tests are specified by running DRT "foo.html'-p"
              dumpRenderTreeOptions.add('--notree');
              fullHtmlPath = "${fullHtmlPath}'-p";
            }
          }
          commandSet.add(new DumpRenderTreeCommand(dumpRenderTreeFilename,
                                                   fullHtmlPath,
                                                   dumpRenderTreeOptions,
                                                   dartFlags,
                                                   expectedOutput));
        }

        // Create BrowserTestCase and queue it.
        String testDisplayName = '$suiteName/$testName';
        var testCase;
        if (info.optionsFromFile['isMultiHtmlTest']) {
          testDisplayName = '$testDisplayName/${subtestNames[subtestIndex]}';
          testCase = new BrowserTestCase(testDisplayName,
              commandSet, configuration, completeHandler,
              expectations['$testName/${subtestNames[subtestIndex]}'],
              info, info.hasCompileError || info.hasRuntimeError,
              subtestIndex != 0);
        } else {
          testCase = new BrowserTestCase(testDisplayName,
              commandSet, configuration, completeHandler, expectations,
              info, info.hasCompileError || info.hasRuntimeError, false);
        }
        if (subtestIndex == 0) {
          multitestParentTest = testCase;
        } else {
          multitestParentTest.addObserver(testCase);
        }
        doTest(testCase);
        subtestIndex++;
      } while(subtestIndex < subtestNames.length);
    }
  }

  /** Helper to create a compilation command for a single input file. */
  Command _compileCommand(String inputFile, String outputFile,
      String compiler, String dir, vmOptions, optionsFromFile) {
    String executable = compilerPath;
    List<String> args = TestUtils.standardOptions(configuration);
    switch (compiler) {
      case 'dart2js':
      case 'dart2dart':
        String packageRoot =
          packageRootArgument(optionsFromFile['packageRoot']);
        if (packageRoot != null) {
          args.add(packageRoot);
        }
        args.add('--out=$outputFile');
        args.add(inputFile);
        break;
      default:
        print('unimplemented compiler $compiler');
        exit(1);
    }
    if (executable.endsWith('.dart')) {
      // Run the compiler script via the Dart VM.
      args.insert(0, executable);
      executable = dartShellFileName;
    }
    if (['dart2js', 'dart2dart'].contains(configuration['compiler'])) {
      return new CompilationCommand(outputFile,
                                   !useSdk,
                                   dart2JsBootstrapDependencies,
                                   compilerPath,
                                   args);
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
    if (!optionsName.isEmpty) {
      testUniqueName = '$testUniqueName-$optionsName';
    }

    // Create '[build dir]/generated_tests/$compiler-$runtime/$testUniqueName',
    // including any intermediate directories that don't exist.
    // If the tests are run in checked or minified mode we add that to the
    // '$compile-$runtime' directory name.
    var checked = configuration['checked'] ? '-checked' : '';
    var minified = configuration['minified'] ? '-minified' : '';
    var csp = configuration['csp'] ? '-csp' : '';
    var dirName = "${configuration['compiler']}-${configuration['runtime']}"
                  "$checked$minified$csp";
    Path generatedTestPath = new Path(buildDir)
        .append('generated_tests')
        .append(dirName)
        .append(testUniqueName);

    TestUtils.mkdirRecursive(new Path('.'), generatedTestPath);
    return new File.fromPath(generatedTestPath).fullPathSync()
        .replaceAll('\\', '/');
  }

  String get scriptType {
    switch (configuration['compiler']) {
      case 'none':
      case 'dart2dart':
        return 'application/dart';
      case 'dart2js':
      case 'dartanalyzer':
      case 'dartc':
        return 'text/javascript';
      default:
        print('Non-web runtime, so no scriptType for: '
                    '${configuration["compiler"]}');
        exit(1);
        return null;
    }
  }

  bool get hasRuntime {
    switch(configuration['runtime']) {
      case 'none':
        return false;
      default:
        return true;
    }
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

  void completeHandler(TestCase testCase) {
  }

  List<String> commonArgumentsFromFile(Path filePath, Map optionsFromFile) {
    List args = TestUtils.standardOptions(configuration);

    String packageRoot = packageRootArgument(optionsFromFile['packageRoot']);
    if (packageRoot != null) {
      args.add(packageRoot);
    }
    args.addAll(additionalOptions(filePath));
    if (configuration['analyzer']) {
      args.add('--machine');
    }

    bool isMultitest = optionsFromFile["isMultitest"];
    List<String> dartOptions = optionsFromFile["dartOptions"];
    List<List<String>> vmOptionsList = getVmOptions(optionsFromFile);
    assert(!isMultitest || dartOptions == null);
    if (dartOptions == null) {
      args.add(filePath.toNativePath());
    } else {
      var executable_name = dartOptions[0];
      // TODO(ager): Get rid of this hack when the runtime checkout goes away.
      var file = new File(executable_name);
      if (!file.existsSync()) {
        executable_name = '../$executable_name';
        assert(new File(executable_name).existsSync());
        dartOptions[0] = executable_name;
      }
      args.addAll(dartOptions);
    }

    return args;
  }

  String packageRoot(String packageRootFromFile) {
    if (packageRootFromFile == "none") {
      return null;
    }
    String packageRoot = packageRootFromFile;
    if (packageRootFromFile == null) {
      packageRoot = "$buildDir/packages/";
    }
    return packageRoot;
  }

  String packageRootArgument(String packageRootFromFile) {
    var packageRootPath = packageRoot(packageRootFromFile);
    if (packageRootPath == null) {
      return null;
    }
    return "--package-root=$packageRootPath";
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
   *   using an explicit import to a part of the the dart:html library:
   *
   *     import 'dart:html';
   *     import 'dart:web_audio';
   *     import 'dart:indexed_db';
   *     import 'dart:svg';
   *     import 'dart:web_sql';
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
   *
   * This method is static as the map is cached and shared amongst
   * configurations, so it may not use [configuration].
   */
  Map readOptionsFromFile(Path filePath) {
    if (filePath.segments().contains('co19')) {
      return readOptionsFromCo19File(filePath);
    }
    RegExp testOptionsRegExp = new RegExp(r"// VMOptions=(.*)");
    RegExp dartOptionsRegExp = new RegExp(r"// DartOptions=(.*)");
    RegExp otherScriptsRegExp = new RegExp(r"// OtherScripts=(.*)");
    RegExp packageRootRegExp = new RegExp(r"// PackageRoot=(.*)");
    RegExp multiHtmlTestRegExp =
        new RegExp(r"useHtmlIndividualConfiguration()");
    RegExp staticTypeRegExp =
        new RegExp(r"/// ([0-9][0-9]:){0,1}\s*static type warning");
    RegExp compileTimeRegExp =
        new RegExp(r"/// ([0-9][0-9]:){0,1}\s*compile-time error");
    RegExp staticCleanRegExp = new RegExp(r"// @static-clean");
    RegExp isolateStubsRegExp = new RegExp(r"// IsolateStubs=(.*)");
    // TODO(gram) Clean these up once the old directives are not supported.
    RegExp domImportRegExp =
        new RegExp(r"^[#]?import.*dart:(html|web_audio|indexed_db|svg|web_sql)",
        multiLine: true);

    var bytes = new File.fromPath(filePath).readAsBytesSync();
    String contents = decodeUtf8(bytes);
    bytes = null;

    // Find the options in the file.
    List<List> result = new List<List>();
    List<String> dartOptions;
    String packageRoot;
    bool isStaticClean = false;

    Iterable<Match> matches = testOptionsRegExp.allMatches(contents);
    for (var match in matches) {
      result.add(match[1].split(' ').where((e) => e != '').toList());
    }
    if (result.isEmpty) result.add([]);

    matches = dartOptionsRegExp.allMatches(contents);
    for (var match in matches) {
      if (dartOptions != null) {
        throw new Exception(
            'More than one "// DartOptions=" line in test $filePath');
      }
      dartOptions = match[1].split(' ').where((e) => e != '').toList();
    }

    matches = packageRootRegExp.allMatches(contents);
    for (var match in matches) {
      if (packageRoot != null) {
        throw new Exception(
            'More than one "// PackageRoot=" line in test $filePath');
      }
      packageRoot = match[1];
      if (packageRoot != 'none') {
        // PackageRoot=none means that no package-root option should be given.
        packageRoot = '${filePath.directoryPath.join(new Path(packageRoot))}';
      }
    }

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
      otherScripts.addAll(match[1].split(' ').where((e) => e != '').toList());
    }

    bool isMultitest = multiTestRegExp.hasMatch(contents);
    bool isMultiHtmlTest = multiHtmlTestRegExp.hasMatch(contents);
    Match isolateMatch = isolateStubsRegExp.firstMatch(contents);
    String isolateStubs = isolateMatch != null ? isolateMatch[1] : '';
    bool containsDomImport = domImportRegExp.hasMatch(contents);
    int numStaticTypeAnnotations = 0;
    for (var i in staticTypeRegExp.allMatches(contents)) {
      numStaticTypeAnnotations++;
    }
    int numCompileTimeAnnotations = 0;
    for (var i in compileTimeRegExp.allMatches(contents)) {
      numCompileTimeAnnotations++;
    }

    // Note: This is brittle. It's the age-old problem of having a context free
    // language but the means to easily identify the construct is a regular
    // expression, aka impossible. Therefore we just make an approximation of
    // the number of top-level "group(...)" occurrences. This assumes you import
    // unittest with no prefix and always directly call "group(". It only uses
    // top-level "groups" so tests running nested groups will be no-ops.
    RegExp numTests = new RegExp(r"\s*[^/]\s*group\('[^,']*");
    List<String> subtestNames = [];
    Iterator matchesIter = numTests.allMatches(contents).iterator;
    while(matchesIter.moveNext() && isMultiHtmlTest) {
      String fullMatch = matchesIter.current.group(0);
      subtestNames.add(fullMatch.substring(fullMatch.indexOf("'") + 1));
    }

    return { "vmOptions": result,
             "dartOptions": dartOptions,
             "packageRoot": packageRoot,
             "hasCompileError": false,
             "hasRuntimeError": false,
             "isStaticClean" : isStaticClean,
             "otherScripts": otherScripts,
             "isMultitest": isMultitest,
             "isMultiHtmlTest": isMultiHtmlTest,
             "subtestNames": subtestNames,
             "isolateStubs": isolateStubs,
             "containsDomImport": containsDomImport,
             "numStaticTypeAnnotations": numStaticTypeAnnotations,
             "numCompileTimeAnnotations": numCompileTimeAnnotations };
  }

  List<List<String>> getVmOptions(Map optionsFromFile) {
    var COMPILERS = const ['none', 'dart2dart'];
    var RUNTIMES = const ['none', 'vm', 'drt', 'dartium'];
    var needsVmOptions = COMPILERS.contains(configuration['compiler']) &&
                         RUNTIMES.contains(configuration['runtime']);
    if (!needsVmOptions) return [[]];
    final vmOptions = optionsFromFile['vmOptions'];
    if (configuration['compiler'] != 'dart2dart') return vmOptions;
    // Temporary workaround for race in test suite: tests with different
    // vm options are still compiled into the same output file which
    // may lead to reads from empty files.
    return [vmOptions[0]];
  }

  /**
   * Read options from a co19 test file.
   *
   * The reason this is different from [readOptionsFromFile] is that
   * co19 is developed based on a contract which defines certain test
   * tags. These tags may appear unused, but should not be removed
   * without consulting with the co19 team.
   *
   * Also, [readOptionsFromFile] recognizes a number of additional
   * tags that are not appropriate for use in general tests of
   * conformance to the Dart language. Any Dart implementation must
   * pass the co19 test suite as is, and not require extra flags,
   * environment variables, configuration files, etc.
   */
  Map readOptionsFromCo19File(Path filePath) {
    String contents = decodeUtf8(new File.fromPath(filePath).readAsBytesSync());

    bool hasCompileError = contents.contains("@compile-error");
    bool hasRuntimeError = contents.contains("@runtime-error");
    bool hasDynamicTypeError = contents.contains("@dynamic-type-error");
    bool hasStaticWarning = contents.contains("@static-warning");
    bool isMultitest = multiTestRegExp.hasMatch(contents);

    if (hasDynamicTypeError) {
      // TODO(ahe): Remove this warning when co19 no longer uses this tag.

      // @dynamic-type-error has been replaced by tests that use
      // tests/co19/src/Utils/dynamic_check.dart to dynamically detect
      // if a test is running in checked mode or not and change its
      // expectations accordingly.

      // Using stderr.writeString to avoid breaking dartc/junit_tests
      // which parses the output of the --list option.
      stderr.writeln(
          "Warning: deprecated @dynamic-type-error tag used in $filePath");
    }

    return {
      "vmOptions": <List>[[]],
      "dartOptions": null,
      "packageRoot": null,
      "hasCompileError": hasCompileError,
      "hasRuntimeError": hasRuntimeError,
      "isStaticClean" : !hasStaticWarning,
      "otherScripts": <String>[],
      "isMultitest": isMultitest,
      "isMultiHtmlTest": false,
      "subtestNames": <String>[],
      "isolateStubs": '',
      "containsDomImport": false,
      "numStaticTypeAnnotations": 0,
      "numCompileTimeAnnotations": 0,
    };
  }
}


/// A DartcCompilationTestSuite will run dartc on all of the tests.
///
/// Usually, the result of a dartc run is determined by the output of
/// dartc in connection with annotations in the test file.
///
/// If you want each file that you are running as a test to have no
/// static warnings or errors you can create a DartcCompilationTestSuite
/// with the optional allStaticClean constructor parameter set to true.
class DartcCompilationTestSuite extends StandardTestSuite {
  List<String> _testDirs;
  bool allStaticClean;

  DartcCompilationTestSuite(Map configuration,
                            String suiteName,
                            String directoryPath,
                            List<String> this._testDirs,
                            List<String> expectations,
                            {bool this.allStaticClean: false})
      : super(configuration,
              suiteName,
              new Path(directoryPath),
              expectations);

  List<String> additionalOptions(Path filePath) {
    return ['--fatal-warnings', '--fatal-type-errors'];
  }

  Future enqueueTests() {
    var group = new FutureGroup();

    for (String testDir in _testDirs) {
      Directory dir = new Directory.fromPath(suiteDir.append(testDir));
      if (dir.existsSync()) {
        enqueueDirectory(dir, group);
      }
    }

    return group.future;
  }

  Map readOptionsFromFile(Path p) {
    Map options = super.readOptionsFromFile(p);
    if (allStaticClean) {
      options['isStaticClean'] = true;
    }
    return options;
  }
}


class JUnitTestSuite extends TestSuite {
  String directoryPath;
  String statusFilePath;
  final String dartDir;
  String classPath;
  List<String> testClasses;
  TestCaseEvent doTest;
  VoidFunction doDone;
  TestExpectations testExpectations;

  JUnitTestSuite(Map configuration,
                 String suiteName,
                 String this.directoryPath,
                 String this.statusFilePath)
      : super(configuration, suiteName),
        dartDir = TestUtils.dartDir().toNativePath();

  bool isTestFile(String filename) => filename.endsWith("Tests.java") &&
      !filename.contains('com/google/dart/compiler/vm') &&
      !filename.contains('com/google/dart/corelib/SharedTests.java');

  void forEachTest(TestCaseEvent onTest,
                   Map testCacheIgnored,
                   [VoidFunction onDone]) {
    doTest = onTest;
    doDone = onDone;

    if (!configuration['analyzer']) {
      // Do nothing. Asynchronously report that the suite is enqueued.
      asynchronously(doDone);
      return;
    }
    RegExp pattern = configuration['selectors']['dartc'];
    if (!pattern.hasMatch('junit_tests')) {
      asynchronously(doDone);
      return;
    }

    computeClassPath();
    testClasses = <String>[];
    // Do not read the status file.
    // All exclusions are hardcoded in this script, as they are in testcfg.py.
    processDirectory();
  }

  void processDirectory() {
    directoryPath = '$dartDir/$directoryPath';
    Directory dir = new Directory(directoryPath);

    dir.list(recursive: true).listen((FileSystemEntity fse) {
      if (fse is File) processFile(fse.path);
    },
    onDone: createTest);
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

  void createTest() {
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
    classPath =
        ['$buildDir/analyzer/util/analyzer/dart_analyzer.jar',
         '$buildDir/analyzer/dart_analyzer_tests.jar',
         // Third party libraries.
         '$dartDir/third_party/args4j/2.0.12/args4j-2.0.12.jar',
         '$dartDir/third_party/guava/r13/guava-13.0.1.jar',
         '$dartDir/third_party/rhino/1_7R3/js.jar',
         '$dartDir/third_party/hamcrest/v1_3/hamcrest-core-1.3.0RC2.jar',
         '$dartDir/third_party/hamcrest/v1_3/hamcrest-generator-1.3.0RC2.jar',
         '$dartDir/third_party/hamcrest/v1_3/hamcrest-integration-1.3.0RC2.jar',
         '$dartDir/third_party/hamcrest/v1_3/hamcrest-library-1.3.0RC2.jar',
         '$dartDir/third_party/junit/v4_8_2/junit.jar']
        .join(Platform.operatingSystem == 'windows'? ';': ':');  // Path separator.
  }
}

class LastModifiedCache {
  Map<String, DateTime> _cache = <String, DateTime>{};

  /**
   * Returns the last modified date of the given [uri].
   *
   * The return value will be cached for future queries. If [uri] is a local
   * file, it's last modified [Date] will be returned. If the file does not
   * exist, null will be returned instead.
   * In case [uri] is not a local file, this method will always return
   * the current date.
   */
  DateTime getLastModified(Uri uri) {
    if (uri.scheme == "file") {
      if (_cache.containsKey(uri.path)) {
        return _cache[uri.path];
      }
      var file = new File(new Path(uri.path).toNativePath());
      _cache[uri.path] = file.existsSync() ? file.lastModifiedSync() : null;
      return _cache[uri.path];
    }
    return new Date.now();
  }
}

class TestUtils {
  /**
   * The libraries in this directory relies on finding various files
   * relative to the 'test.dart' script in '.../dart/tools/test.dart'. If
   * the main script using 'test_suite.dart' is not there, the main
   * script must set this to '.../dart/tools/test.dart'.
   */
  static String testScriptPath = new Options().script;
  static LastModifiedCache lastModifiedCache = new LastModifiedCache();
  static Path currentWorkingDirectory =
      new Path(new Directory.current().path);
  /**
   * Creates a directory using a [relativePath] to an existing
   * [base] directory if that [relativePath] does not already exist.
   */
  static Directory mkdirRecursive(Path base, Path relativePath) {
    if (relativePath.isAbsolute) {
      base = new Path('/');
    }
    Directory dir = new Directory.fromPath(base);
    assert(dir.existsSync());
    var segments = relativePath.segments();
    for (String segment in segments) {
      base = base.append(segment);
      if (base.toString() == "/$segment" &&
          segment.length == 2 &&
          segment.endsWith(':')) {
        // Skip the directory creation for a path like "/E:".
        continue;
      }
      dir = new Directory.fromPath(base);
      if (!dir.existsSync()) {
        dir.createSync();
      }
      assert(dir.existsSync());
    }
    return dir;
  }

  /**
   * Copy a [source] file to a new place.
   * Assumes that the directory for [dest] already exists.
   */
  static Future copyFile(Path source, Path dest) {
    return new File.fromPath(source).openRead()
        .pipe(new File.fromPath(dest).openWrite());
  }

  static Path debugLogfile() {
    return new Path(".debug.log");
  }

  static String flakyFileName() {
    // If a flaky test did fail, infos about it (i.e. test name, stdin, stdout)
    // will be written to this file. This is useful for the debugging of
    // flaky tests.
    // When running on a built bot, the file can be made visible in the
    // waterfall UI.
    return ".flaky.log";
  }

  static void ensureExists(String filename, Map configuration) {
    if (!configuration['list'] && !(new File(filename).existsSync())) {
      throw "Executable '$filename' does not exist";
    }
  }

  static Path absolutePath(Path path) {
    if (!path.isAbsolute) {
      return currentWorkingDirectory.join(path);
    }
    return path;
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

  static Path dartDir() {
    File scriptFile = new File(testScriptPath);
    Path scriptPath = new Path(scriptFile.fullPathSync());
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
        args.add("--categories=all");
      }
    }
    if ((compiler == "dart2js" || compiler == "dart2dart") &&
        configuration["minified"]) {
      args.add("--minify");
    }
    if (compiler == "dart2js" && configuration["csp"]) {
      args.add("--disallow-unsafe-eval");
    }
    return args;
  }

  static bool usesWebDriver(String runtime) {
    const BROWSERS = const [
      'dartium',
      'ie9',
      'ie10',
      'safari',
      'opera',
      'chrome',
      'ff'
    ];
    return BROWSERS.contains(runtime);
  }

  static bool isBrowserRuntime(String runtime) =>
      runtime == 'drt' || TestUtils.usesWebDriver(runtime);

  static bool isJsCommandLineRuntime(String runtime) =>
      const ['d8', 'jsshell'].contains(runtime);

  static bool isCommandLineAnalyzer(String compiler) =>
      compiler == 'dartc' || compiler == 'dartanalyzer';

  static String buildDir(Map configuration) {
    // FIXME(kustermann,ricow): Our code assumes that the returned 'buildDir'
    // is relative to the current working directory.
    // Thus, if we pass in an absolute path (e.g. '--build-directory=/tmp/out')
    // we get into trouble.
    if (configuration['build_directory'] != '') {
      return configuration['build_directory'];
    }
    var outputDir = '';
    var system = configuration['system'];
    if (system == 'linux') {
      outputDir = 'out/';
    } else if (system == 'macos') {
      outputDir = 'xcodebuild/';
    } else if (system == 'windows') {
      outputDir = 'build/';
    }
    return "$outputDir${configurationDir(configuration)}";
  }

  static String configurationDir(Map configuration) {
    // For regular dart checkouts, the configDir by default is mode+arch.
    // For Dartium, the configDir by default is mode (as defined by the Chrome
    // build setup). We can detect this because in the dartium checkout, the
    // "output" directory is a sibling of the dart directory instead of a child.
    var mode = (configuration['mode'] == 'debug') ? 'Debug' : 'Release';
    var arch = configuration['arch'].toUpperCase();
    if (currentWorkingDirectory != dartDir()) {
      return '$mode$arch';
    } else {
      return mode;
    }
  }

  /**
   * Returns the path to the dart binary checked into the repo, used for
   * bootstrapping test.dart.
   */
  static Path get dartTestExecutable {
    var path = '${TestUtils.dartDir()}/tools/testing/bin/'
        '${Platform.operatingSystem}/dart';
    if (Platform.operatingSystem == 'windows') {
      path = '$path.exe';
    }
    return new Path(path);
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
  static int compileErrorSkip = 0;

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

  static void addCompileErrorSkipTest() {
    total++;
    compileErrorSkip++;
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
 * $compileErrorSkip tests are skipped on browsers due to compile-time error
""";
    print(report);
   }
}
