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
import 'dart:async';
import 'dart:io';

import "package:status_file/expectation.dart";

import 'browser_test.dart';
import 'command.dart';
import 'compiler_configuration.dart';
import 'configuration.dart';
import 'expectation_set.dart';
import 'html_test.dart' as html_test;
import 'http_server.dart';
import 'multitest.dart';
import 'path.dart';
import 'repository.dart';
import 'runtime_updater.dart';
import 'summary_report.dart';
import 'test_configurations.dart';
import 'test_runner.dart';
import 'utils.dart';

RegExp multiHtmlTestGroupRegExp = new RegExp(r"\s*[^/]\s*group\('[^,']*");
RegExp multiHtmlTestRegExp = new RegExp(r"useHtmlIndividualConfiguration()");
// Require at least one non-space character before '//[/#]'
RegExp multiTestRegExp = new RegExp(r"\S *"
    r"//[#/] \w+:(.*)");
RegExp dartExtension = new RegExp(r'\.dart$');

/**
 * A simple function that tests [arg] and returns `true` or `false`.
 */
typedef bool Predicate<T>(T arg);

typedef void CreateTest(Path filePath, Path originTestPath,
    {bool hasSyntaxError,
    bool hasCompileError,
    bool hasRuntimeError,
    bool isNegativeIfChecked,
    bool hasCompileErrorIfChecked,
    bool hasStaticWarning,
    String multitestKey});

typedef void VoidFunction();

/**
 * Calls [function] asynchronously. Returns a future that completes with the
 * result of the function. If the function is `null`, returns a future that
 * completes immediately with `null`.
 */
Future asynchronously<T>(T function()) {
  if (function == null) return new Future<T>.value(null);

  var completer = new Completer<T>();
  Timer.run(() => completer.complete(function()));

  return completer.future;
}

/** A completer that waits until all added [Future]s complete. */
// TODO(rnystrom): Copied from web_components. Remove from here when it gets
// added to dart:core. (See #6626.)
class FutureGroup {
  static const _FINISHED = -1;
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
    var handledTaskFuture = task.catchError((e, StackTrace s) {
      if (!wasCompleted) {
        _completer.completeError(e, s);
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
  final Configuration configuration;
  final String suiteName;
  final List<String> statusFilePaths;
  // This function is set by subclasses before enqueueing starts.
  Function doTest;
  Map<String, String> _environmentOverrides;

  TestSuite(this.configuration, this.suiteName, this.statusFilePaths) {
    _environmentOverrides = {
      'DART_CONFIGURATION': configuration.configurationDirectory,
    };

    if (useSdk && configuration.usingDart2VMWrapper) {
      _environmentOverrides['DART_USE_SDK'] = '1';
    }
  }

  Map<String, String> get environmentOverrides => _environmentOverrides;

  /**
   * Whether or not binaries should be found in the root build directory or
   * in the built SDK.
   */
  bool get useSdk => configuration.useSdk;

  /**
   * The output directory for this suite's configuration.
   */
  String get buildDir => configuration.buildDirectory;

  /**
   * The path to the compiler for this suite's configuration. Returns `null` if
   * no compiler should be used.
   */
  String get compilerPath {
    var compilerConfiguration = configuration.compilerConfiguration;
    if (!compilerConfiguration.hasCompiler) return null;
    var name = compilerConfiguration.computeCompilerPath();

    // TODO(ahe): Only validate this once, in test_options.dart.
    TestUtils.ensureExists(name, configuration);
    return name;
  }

  /// Returns the name of the Dart VM executable.
  String get dartVmBinaryFileName {
    // Controlled by user with the option "--dart".
    var dartExecutable = configuration.dartPath;

    if (configuration.usingDart2VMWrapper) {
      if (dartExecutable != null) {
        throw 'Can not use --dart when testing Dart 2.0 configuration';
      }

      dartExecutable = 'pkg/vm/tool/dart2$executableScriptSuffix';
    }

    if (dartExecutable == null) {
      dartExecutable = dartVmExecutableFileName;
    }

    TestUtils.ensureExists(dartExecutable, configuration);
    return dartExecutable;
  }

  String get dartVmExecutableFileName {
    return useSdk
        ? '$buildDir/dart-sdk/bin/dart$executableBinarySuffix'
        : '$buildDir/dart$executableBinarySuffix';
  }

  /// Returns the name of the flutter engine executable.
  String get flutterEngineBinaryFileName {
    // Controlled by user with the option "--flutter".
    var flutterExecutable = configuration.flutterPath;
    TestUtils.ensureExists(flutterExecutable, configuration);
    return flutterExecutable;
  }

  String get dartPrecompiledBinaryFileName {
    // Controlled by user with the option "--dart_precompiled".
    var dartExecutable = configuration.dartPrecompiledPath;

    if (dartExecutable == null || dartExecutable == '') {
      var suffix = executableBinarySuffix;
      dartExecutable = '$buildDir/dart_precompiled_runtime$suffix';
    }

    TestUtils.ensureExists(dartExecutable, configuration);
    return dartExecutable;
  }

  String get processTestBinaryFileName {
    var suffix = executableBinarySuffix;
    var processTestExecutable = '$buildDir/process_test$suffix';
    TestUtils.ensureExists(processTestExecutable, configuration);
    return processTestExecutable;
  }

  String get d8FileName {
    var suffix = getExecutableSuffix('d8');
    var d8Dir = Repository.dir.append('third_party/d8');
    var d8Path = d8Dir.append('${Platform.operatingSystem}/d8$suffix');
    var d8 = d8Path.toNativePath();
    TestUtils.ensureExists(d8, configuration);
    return d8;
  }

  String get jsShellFileName {
    var executableSuffix = getExecutableSuffix('jsshell');
    var executable = 'jsshell$executableSuffix';
    var jsshellDir = '${Repository.dir.toNativePath()}/tools/testing/bin';
    return '$jsshellDir/$executable';
  }

  /**
   * The file extension (if any) that should be added to the given executable
   * name for the current platform.
   */
  // TODO(ahe): Get rid of this. Use executableBinarySuffix instead.
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

  String get executableBinarySuffix => Platform.isWindows ? '.exe' : '';
  String get executableScriptSuffix => Platform.isWindows ? '.bat' : '';

  /**
   * Call the callback function onTest with a [TestCase] argument for each
   * test in the suite.  When all tests have been processed, call [onDone].
   *
   * The [testCache] argument provides a persistent store that can be used to
   * cache information about the test suite, so that directories do not need
   * to be listed each time.
   */
  Future forEachTest(
      TestCaseEvent onTest, Map<String, List<TestInformation>> testCache,
      [VoidFunction onDone]);

  // This function will be called for every TestCase of this test suite.
  // It will
  //  - handle sharding
  //  - update SummaryReport
  //  - handle SKIP/SKIP_BY_DESIGN markers
  //  - test if the selector matches
  // and will enqueue the test (if necessary).
  void enqueueNewTestCase(
      String testName, List<Command> commands, Set<Expectation> expectations,
      [TestInformation info]) {
    var displayName = '$suiteName/$testName';

    // If the test is not going to be run at all, then a RuntimeError,
    // MissingRuntimeError or Timeout will never occur.
    // Instead, treat that as Pass.
    if (configuration.runtime == Runtime.none) {
      expectations = expectations.toSet();
      expectations.remove(Expectation.runtimeError);
      expectations.remove(Expectation.ok);
      expectations.remove(Expectation.missingRuntimeError);
      expectations.remove(Expectation.timeout);
      if (expectations.isEmpty) expectations.add(Expectation.pass);
    }

    var negative = info != null ? isNegative(info) : false;
    var testCase = new TestCase(
        displayName, commands, configuration, expectations,
        isNegative: negative, info: info);

    if (negative &&
        configuration.runtimeConfiguration.shouldSkipNegativeTests) {
      return;
    }

    // Handle sharding based on the original test path (i.e. all multitests
    // of a given original test belong to the same shard)
    if (configuration.shardCount > 1 &&
        testCase.hash % configuration.shardCount != configuration.shard - 1) {
      return;
    }

    // Test if the selector includes this test.
    var pattern = configuration.selectors[suiteName];
    if (!pattern.hasMatch(displayName)) {
      return;
    }

    if (configuration.hotReload || configuration.hotReloadRollback) {
      // Handle reload special cases.
      if (expectations.contains(Expectation.compileTimeError) ||
          testCase.hasCompileError ||
          testCase.expectCompileError) {
        // Running a test that expects a compilation error with hot reloading
        // is redundant with a regular run of the test.
        return;
      }
    }

    // Update Summary report
    if (configuration.printReport) {
      summaryReport.add(testCase);
    }

    // Handle skipped tests
    if (expectations.contains(Expectation.skip) ||
        expectations.contains(Expectation.skipByDesign) ||
        expectations.contains(Expectation.skipSlow)) {
      return;
    }

    if (configuration.fastTestsOnly &&
        (expectations.contains(Expectation.slow) ||
            expectations.contains(Expectation.skipSlow) ||
            expectations.contains(Expectation.timeout) ||
            expectations.contains(Expectation.dartkTimeout))) {
      return;
    }

    doTest(testCase);
  }

  bool expectCompileError(TestInformation info) {
    return info.hasCompileError ||
        (configuration.isChecked && info.hasCompileErrorIfChecked);
  }

  bool isNegative(TestInformation info) {
    if (info.hasRuntimeError && configuration.runtime != Runtime.none) {
      return true;
    }

    if (info.isNegativeIfChecked && configuration.isChecked) {
      return true;
    }

    return expectCompileError(info);
  }

  String createGeneratedTestDirectoryHelper(
      String name, String dirname, Path testPath) {
    Path relative = testPath.relativeTo(Repository.dir);
    relative = relative.directoryPath.append(relative.filenameWithoutExtension);
    String testUniqueName = TestUtils.getShortName(relative.toString());

    Path generatedTestPath = new Path(buildDir)
        .append('generated_$name')
        .append(dirname)
        .append(testUniqueName);

    TestUtils.mkdirRecursive(new Path('.'), generatedTestPath);
    return new File(generatedTestPath.toNativePath())
        .absolute
        .path
        .replaceAll('\\', '/');
  }

  String buildTestCaseDisplayName(Path suiteDir, Path originTestPath,
      {String multitestName: ""}) {
    Path testNamePath = originTestPath.relativeTo(suiteDir);
    var directory = testNamePath.directoryPath;
    var filenameWithoutExt = testNamePath.filenameWithoutExtension;

    String concat(String base, String part) {
      if (base == "") return part;
      if (part == "") return base;
      return "$base/$part";
    }

    var testName = "$directory";
    testName = concat(testName, "$filenameWithoutExt");
    testName = concat(testName, multitestName);
    return testName;
  }

  /**
   * Create a directories for generated assets (tests, html files,
   * pubspec checkouts ...).
   */

  String createOutputDirectory(Path testPath) {
    var checked = configuration.isChecked ? '-checked' : '';
    var strong = configuration.isStrong ? '-strong' : '';
    var minified = configuration.isMinified ? '-minified' : '';
    var sdk = configuration.useSdk ? '-sdk' : '';
    var dirName = "${configuration.compiler.name}-${configuration.runtime.name}"
        "$checked$strong$minified$sdk";
    return createGeneratedTestDirectoryHelper("tests", dirName, testPath);
  }

  String createCompilationOutputDirectory(Path testPath) {
    var checked = configuration.isChecked ? '-checked' : '';
    var strong = configuration.isStrong ? '-strong' : '';
    var minified = configuration.isMinified ? '-minified' : '';
    var csp = configuration.isCsp ? '-csp' : '';
    var sdk = configuration.useSdk ? '-sdk' : '';
    var dirName = "${configuration.compiler.name}"
        "$checked$strong$minified$csp$sdk";
    return createGeneratedTestDirectoryHelper(
        "compilations", dirName, testPath);
  }

  String createPubspecCheckoutDirectory(Path directoryOfPubspecYaml) {
    var sdk = configuration.useSdk ? 'sdk' : '';
    return createGeneratedTestDirectoryHelper(
        "pubspec_checkouts", sdk, directoryOfPubspecYaml);
  }

  String createPubPackageBuildsDirectory(Path directoryOfPubspecYaml) {
    return createGeneratedTestDirectoryHelper(
        "pub_package_builds", 'public_packages', directoryOfPubspecYaml);
  }
}

/// A specialized [TestSuite] that runs tests written in C to unit test
/// the Dart virtual machine and its API.
///
/// The tests are compiled into a monolithic executable by the build step.
/// The executable lists its tests when run with the --list command line flag.
/// Individual tests are run by specifying them on the command line.
class VMTestSuite extends TestSuite {
  String targetRunnerPath;
  String hostRunnerPath;
  final String dartDir;

  VMTestSuite(Configuration configuration)
      : dartDir = Repository.dir.toNativePath(),
        super(configuration, "vm", ["runtime/tests/vm/vm.status"]) {
    // For running the tests we use the given '$runnerName' binary
    targetRunnerPath = '$buildDir/run_vm_tests';

    // For listing the tests we use the '$runnerName.host' binary if it exists
    // and use '$runnerName' if it doesn't.
    var binarySuffix = Platform.operatingSystem == 'windows' ? '.exe' : '';
    var hostBinary = '$targetRunnerPath.host$binarySuffix';
    if (new File(hostBinary).existsSync()) {
      hostRunnerPath = hostBinary;
    } else {
      hostRunnerPath = targetRunnerPath;
    }
  }

  Future<Null> forEachTest(Function onTest, Map testCache,
      [VoidFunction onDone]) async {
    doTest = onTest;

    var statusFiles =
        statusFilePaths.map((statusFile) => "$dartDir/$statusFile").toList();
    var expectations = new ExpectationSet.read(statusFiles, configuration);

    try {
      for (var name in await _listTests(hostRunnerPath)) {
        _addTest(expectations, name);
      }

      doTest = null;
      if (onDone != null) onDone();
    } catch (error) {
      print("Fatal error occured: $error");
      exit(1);
    }
  }

  void _addTest(ExpectationSet testExpectations, String testName) {
    var args = configuration.standardOptions.toList();
    if (configuration.compilerConfiguration.useDfe) {
      args.add('--use-dart-frontend');
      // '--dfe' has to be the first argument for run_vm_test to pick it up.
      args.insert(0, '--dfe=$buildDir/gen/kernel-service.dart.snapshot');
    }

    if (configuration.isStrong) {
      args.add('--strong');
    }

    args.add(testName);

    var command = Command.process(
        'run_vm_unittest', targetRunnerPath, args, environmentOverrides);
    var fullName = 'cc/$testName';
    var expectations = testExpectations.expectations(fullName);
    enqueueNewTestCase(fullName, [command], expectations);
  }

  Future<Iterable<String>> _listTests(String runnerPath) async {
    var result = await Process.run(runnerPath, ["--list"]);
    if (result.exitCode != 0) {
      throw "Failed to list tests: '$runnerPath --list'. "
          "Process exited with ${result.exitCode}";
    }

    return (result.stdout as String)
        .split('\n')
        .map((line) => line.trim())
        .where((name) => name.isNotEmpty);
  }
}

class TestInformation {
  Path filePath;
  Path originTestPath;
  Map<String, dynamic> optionsFromFile;
  bool hasSyntaxError;
  bool hasCompileError;
  bool hasRuntimeError;
  bool isNegativeIfChecked;
  bool hasCompileErrorIfChecked;
  bool hasStaticWarning;
  String multitestKey;

  TestInformation(
      this.filePath,
      this.originTestPath,
      this.optionsFromFile,
      this.hasSyntaxError,
      this.hasCompileError,
      this.hasRuntimeError,
      this.isNegativeIfChecked,
      this.hasCompileErrorIfChecked,
      this.hasStaticWarning,
      {this.multitestKey: ''}) {
    assert(filePath.isAbsolute);
  }
}

class HtmlTestInformation extends TestInformation {
  List<String> expectedMessages;
  List<String> scripts;

  HtmlTestInformation(Path filePath, this.expectedMessages, this.scripts)
      : super(
            filePath,
            filePath,
            {'isMultitest': false, 'isMultiHtmlTest': false},
            false,
            false,
            false,
            false,
            false,
            false) {}
}

/**
 * A standard [TestSuite] implementation that searches for tests in a
 * directory, and creates [TestCase]s that compile and/or run them.
 */
class StandardTestSuite extends TestSuite {
  final Path suiteDir;
  ExpectationSet testExpectations;
  List<TestInformation> cachedTests;
  final Path dartDir;
  Predicate<String> isTestFilePredicate;
  final bool listRecursively;
  final List<String> extraVmOptions;
  List<Uri> _dart2JsBootstrapDependencies;

  static final Uri co19SuiteLocation = Repository.uri.resolve("tests/co19_2/");
  static final Uri legacyCo19SuiteLocation =
      Repository.uri.resolve("tests/co19/");

  StandardTestSuite(Configuration configuration, String suiteName,
      Path suiteDirectory, List<String> statusFilePaths,
      {this.isTestFilePredicate, bool recursive: false})
      : dartDir = Repository.dir,
        listRecursively = recursive,
        suiteDir = Repository.dir.join(suiteDirectory),
        extraVmOptions = configuration.vmOptions,
        super(configuration, suiteName, statusFilePaths) {
    if (!useSdk) {
      _dart2JsBootstrapDependencies = [];
    } else {
      _dart2JsBootstrapDependencies = [
        Uri.base
            .resolveUri(new Uri.directory(buildDir))
            .resolve('dart-sdk/bin/snapshots/dart2js.dart.snapshot')
      ];
    }
  }

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
      Configuration configuration, Path directory) {
    var name = directory.filename;
    var status_paths = [
      '$directory/$name.status',
      '$directory/.status',
      '$directory/${name}_app_jit.status',
      '$directory/${name}_analyzer.status',
      '$directory/${name}_analyzer2.status',
      '$directory/${name}_dart2js.status',
      '$directory/${name}_dartdevc.status',
      '$directory/${name}_kernel.status',
      '$directory/${name}_precompiled.status',
      '$directory/${name}_spec_parser.status',
      '$directory/${name}_vm.status',
    ];

    return new StandardTestSuite(configuration, name, directory, status_paths,
        isTestFilePredicate: (filename) => filename.endsWith('_test.dart'),
        recursive: true);
  }

  List<Uri> get dart2JsBootstrapDependencies => _dart2JsBootstrapDependencies;

  /**
   * The default implementation assumes a file is a test if
   * it ends in "Test.dart".
   */
  bool isTestFile(String filename) {
    // Use the specified predicate, if provided.
    if (isTestFilePredicate != null) return isTestFilePredicate(filename);
    return filename.endsWith("Test.dart");
  }

  bool isHtmlTestFile(String filename) => filename.endsWith('_htmltest.html');

  List<String> additionalOptions(Path filePath) => [];

  Future forEachTest(
      Function onTest, Map<String, List<TestInformation>> testCache,
      [VoidFunction onDone]) async {
    if (configuration.runtime == Runtime.drt && !configuration.listTests) {
      await updateContentShell(configuration.drtPath);
    }

    doTest = onTest;
    testExpectations = readExpectations();

    // Check if we have already found and generated the tests for this suite.
    if (!testCache.containsKey(suiteName)) {
      cachedTests = testCache[suiteName] = <TestInformation>[];
      await enqueueTests();
    } else {
      for (var info in testCache[suiteName]) {
        enqueueTestCaseFromTestInformation(info);
      }
    }
    testExpectations = null;
    cachedTests = null;
    doTest = null;
    if (onDone != null) onDone();
  }

  /**
   * Reads the status files and completes with the parsed expectations.
   */
  ExpectationSet readExpectations() {
    var statusFiles = statusFilePaths.where((String statusFilePath) {
      var file = new File(dartDir.append(statusFilePath).toNativePath());
      return file.existsSync();
    }).map((statusFilePath) {
      return dartDir.append(statusFilePath).toNativePath();
    }).toList();

    return new ExpectationSet.read(statusFiles, configuration);
  }

  Future enqueueTests() {
    Directory dir = new Directory(suiteDir.toNativePath());
    return dir.exists().then((exists) {
      if (!exists) {
        print('Directory containing tests missing: ${suiteDir.toNativePath()}');
        return new Future.value(null);
      } else {
        var group = new FutureGroup();
        enqueueDirectory(dir, group);
        return group.future;
      }
    });
  }

  void enqueueDirectory(Directory dir, FutureGroup group) {
    var lister = dir
        .list(recursive: listRecursively)
        .where((fse) => fse is File)
        .forEach((FileSystemEntity entity) {
      enqueueFile((entity as File).path, group);
    });
    group.add(lister);
  }

  void enqueueFile(String filename, FutureGroup group) {
    bool match = false;
    for (var regex in configuration.selectors.values) {
      String pattern = regex.pattern;
      if (pattern.contains("/")) {
        String lastPart = pattern.substring(pattern.lastIndexOf("/") + 1);
        if (int.parse(lastPart, onError: (_) => -1) >= 0 ||
            lastPart.toLowerCase() == "none") {
          pattern = pattern.substring(0, pattern.lastIndexOf("/"));
        }
      }
      if (pattern != regex.pattern) {
        regex = new RegExp(pattern);
      }
      if (regex.hasMatch(filename)) match = true;
      if (match) break;
    }
    if (!match) return;

    if (isHtmlTestFile(filename)) {
      var info = html_test.getInformation(filename);
      if (info == null) {
        DebugLogger
            .error("HtmlTest $filename does not contain required annotations");
        return;
      }
      cachedTests.add(info);
      enqueueTestCaseFromTestInformation(info);
      return;
    }
    if (!isTestFile(filename)) return;
    Path filePath = new Path(filename);

    var optionsFromFile = readOptionsFromFile(new Uri.file(filename));
    CreateTest createTestCase = makeTestCaseCreator(optionsFromFile);

    if (optionsFromFile['isMultitest'] as bool) {
      group.add(doMultitest(filePath, buildDir, suiteDir, createTestCase,
          configuration.hotReload || configuration.hotReloadRollback));
    } else {
      createTestCase(filePath, filePath,
          hasSyntaxError: optionsFromFile['hasSyntaxError'] as bool,
          hasCompileError: optionsFromFile['hasCompileError'] as bool,
          hasRuntimeError: optionsFromFile['hasRuntimeError'] as bool,
          hasStaticWarning: optionsFromFile['hasStaticWarning'] as bool);
    }
  }

  void enqueueTestCaseFromTestInformation(TestInformation info) {
    String testName = buildTestCaseDisplayName(suiteDir, info.originTestPath,
        multitestName: info.optionsFromFile['isMultitest'] as bool
            ? info.multitestKey
            : "");
    if (info is HtmlTestInformation) {
      _enqueueHtmlTest(info, testName);
      return;
    }

    var optionsFromFile = info.optionsFromFile;

    // If this test is inside a package, we will check if there is a
    // pubspec.yaml file and if so, create a custom package root for it.
    Path packageRoot;
    Path packages;

    if (optionsFromFile['packageRoot'] == null &&
        optionsFromFile['packages'] == null) {
      if (configuration.packageRoot != null) {
        packageRoot = new Path(configuration.packageRoot);
        optionsFromFile['packageRoot'] = packageRoot.toNativePath();
      }
      if (configuration.packages != null) {
        Path packages = new Path(configuration.packages);
        optionsFromFile['packages'] = packages.toNativePath();
      }
    }
    if (configuration.compilerConfiguration.hasCompiler &&
        expectCompileError(info)) {
      // If a compile-time error is expected, and we're testing a
      // compiler, we never need to attempt to run the program (in a
      // browser or otherwise).
      enqueueStandardTest(info, testName);
    } else if (configuration.runtime.isBrowser) {
      var expectationsMap = <String, Set<Expectation>>{};

      if (info.optionsFromFile['isMultiHtmlTest'] as bool) {
        // A browser multi-test has multiple expectations for one test file.
        // Find all the different sub-test expectations for one entire test
        // file.
        var subtestNames = info.optionsFromFile['subtestNames'] as List<String>;
        expectationsMap = <String, Set<Expectation>>{};
        for (var subtest in subtestNames) {
          expectationsMap[subtest] =
              testExpectations.expectations('$testName/$subtest');
        }
      } else {
        expectationsMap[testName] = testExpectations.expectations(testName);
      }

      _enqueueBrowserTest(
          packageRoot, packages, info, testName, expectationsMap);
    } else {
      enqueueStandardTest(info, testName);
    }
  }

  void enqueueStandardTest(TestInformation info, String testName) {
    var commonArguments =
        commonArgumentsFromFile(info.filePath, info.optionsFromFile);

    // TODO(floitsch): Hack. When running the 2.0 tests always start
    // async functions synchronously.
    if (suiteName.endsWith("_2")) {
      commonArguments.insert(0, "--sync-async");
    }

    var vmOptionsList = getVmOptions(info.optionsFromFile);
    assert(!vmOptionsList.isEmpty);

    for (var vmOptionsVariant = 0;
        vmOptionsVariant < vmOptionsList.length;
        vmOptionsVariant++) {
      var vmOptions = vmOptionsList[vmOptionsVariant];
      var allVmOptions = vmOptions;
      if (!extraVmOptions.isEmpty) {
        allVmOptions = vmOptions.toList()..addAll(extraVmOptions);
      }

      // TODO(rnystrom): Hack. When running the 2.0 tests, always implicitly
      // turn on reified generics in the VM.
      // Note that VMOptions=--no-reify-generic-functions in test is ignored.
      // Also, enable Dart 2.0 fixed-size integers with --limit-ints-to-64-bits.
      // Dart 2 VM wrapper (pkg/vm/tool/dart2) already passes correct arguments.
      if (suiteName.endsWith("_2") && !configuration.usingDart2VMWrapper) {
        allVmOptions = allVmOptions.toList()
          ..add("--reify-generic-functions")
          ..add("--limit-ints-to-64-bits");
      }

      var commands =
          makeCommands(info, vmOptionsVariant, allVmOptions, commonArguments);
      var expectations = testExpectations.expectations(testName);
      enqueueNewTestCase(testName, commands, expectations, info);
    }
  }

  List<Command> makeCommands(TestInformation info, int vmOptionsVariant,
      List<String> vmOptions, List<String> args) {
    var commands = <Command>[];
    var compilerConfiguration = configuration.compilerConfiguration;
    var sharedOptions = info.optionsFromFile['sharedOptions'] as List<String>;
    var dart2jsOptions = info.optionsFromFile['dart2jsOptions'] as List<String>;
    var ddcOptions = info.optionsFromFile['ddcOptions'] as List<String>;

    var compileTimeArguments = <String>[];
    String tempDir;
    if (compilerConfiguration.hasCompiler) {
      compileTimeArguments = compilerConfiguration.computeCompilerArguments(
          vmOptions, sharedOptions, dart2jsOptions, ddcOptions, args);
      // Avoid doing this for analyzer.
      var path = info.filePath;
      if (vmOptionsVariant != 0) {
        // Ensure a unique directory for each test case.
        path = path.join(new Path(vmOptionsVariant.toString()));
      }
      tempDir = createCompilationOutputDirectory(path);

      var otherResources =
          info.optionsFromFile['otherResources'] as List<String>;
      for (var name in otherResources) {
        var namePath = new Path(name);
        var fromPath = info.filePath.directoryPath.join(namePath);
        new File('$tempDir/$name').parent.createSync(recursive: true);
        new File(fromPath.toNativePath()).copySync('$tempDir/$name');
      }
    }

    CommandArtifact compilationArtifact =
        compilerConfiguration.computeCompilationArtifact(
            tempDir, compileTimeArguments, environmentOverrides);
    if (!configuration.skipCompilation) {
      commands.addAll(compilationArtifact.commands);
    }

    if (expectCompileError(info) &&
        compilerConfiguration.hasCompiler &&
        !compilerConfiguration.runRuntimeDespiteMissingCompileTimeError) {
      // Do not attempt to run the compiled result. A compilation
      // error should be reported by the compilation command.
      return commands;
    }

    List<String> runtimeArguments =
        compilerConfiguration.computeRuntimeArguments(
            configuration.runtimeConfiguration,
            info,
            vmOptions,
            sharedOptions,
            args,
            compilationArtifact);

    Map<String, String> environment = environmentOverrides;
    Map<String, String> extraEnv = info.optionsFromFile['environment'];
    if (extraEnv != null) {
      environment = new Map.from(environment)..addAll(extraEnv);
    }

    return commands
      ..addAll(configuration.runtimeConfiguration.computeRuntimeCommands(
          this, compilationArtifact, runtimeArguments, environment));
  }

  CreateTest makeTestCaseCreator(Map<String, dynamic> optionsFromFile) {
    return (Path filePath, Path originTestPath,
        {bool hasSyntaxError,
        bool hasCompileError,
        bool hasRuntimeError,
        bool isNegativeIfChecked: false,
        bool hasCompileErrorIfChecked: false,
        bool hasStaticWarning: false,
        String multitestKey}) {
      // Cache the test information for each test case.
      var info = new TestInformation(
          filePath,
          originTestPath,
          optionsFromFile,
          hasSyntaxError,
          hasCompileError,
          hasRuntimeError,
          isNegativeIfChecked,
          hasCompileErrorIfChecked,
          hasStaticWarning,
          multitestKey: multitestKey);
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
    file = file.absolute;

    var relativeBuildDir = new Path(configuration.buildDirectory);
    var buildDir = relativeBuildDir.absolute;
    var dartDir = Repository.dir.absolute;

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
    return null;
  }

  String _uriForBrowserTest(String pathComponent, [String subtestName]) {
    // Note: If we run test.py with the "--list" option, no http servers
    // will be started. So we return a dummy url instead.
    if (configuration.listTests) {
      return Uri.parse('http://listing_the_tests_only').toString();
    }

    var serverPort = configuration.servers.port;
    var crossOriginPort = configuration.servers.crossOriginPort;
    var parameters = {'crossOriginPort': crossOriginPort.toString()};
    if (subtestName != null) {
      parameters['group'] = subtestName;
    }
    return new Uri(
            scheme: 'http',
            host: configuration.localIP,
            port: serverPort,
            path: pathComponent,
            queryParameters: parameters)
        .toString();
  }

  /// Enqueues a test that runs in a browser.
  ///
  /// Creates a [Command] that compiles the test to JavaScript and writes that
  /// in a generated output directory. Any additional framework and HTML files
  /// are put there too. Then adds another [Command] the spawn the browser and
  /// run the test.
  ///
  /// In order to handle browser multitests, [expectations] is a map of subtest
  /// names to expectation sets. If the test is not a multitest, the map has
  /// a single key, [testName].
  void _enqueueBrowserTest(
      Path packageRoot,
      Path packages,
      TestInformation info,
      String testName,
      Map<String, Set<Expectation>> expectations) {
    var tempDir = createOutputDirectory(info.filePath);
    var fileName = info.filePath.toNativePath();
    var optionsFromFile = info.optionsFromFile;
    var compilationTempDir = createCompilationOutputDirectory(info.filePath);
    var jsWrapperFileName = '$compilationTempDir/test.js';
    var nameNoExt = info.filePath.filenameWithoutExtension;

    // Use existing HTML document if available.
    String content;
    var customHtml = new File(
        info.filePath.directoryPath.append('$nameNoExt.html').toNativePath());
    if (customHtml.existsSync()) {
      jsWrapperFileName = '$tempDir/$nameNoExt.js';
      content = customHtml.readAsStringSync().replaceAll(
          '%TEST_SCRIPTS%', '<script src="$nameNoExt.js"></script>');
    } else {
      // Synthesize an HTML file for the test.
      if (configuration.compiler == Compiler.dart2js) {
        var scriptPath = _createUrlPathFromFile(new Path(jsWrapperFileName));
        content = dart2jsHtml(fileName, scriptPath);
      } else {
        var jsDir =
            new Path(compilationTempDir).relativeTo(Repository.dir).toString();
        jsWrapperFileName =
            new Path('$compilationTempDir/$nameNoExt.js').toNativePath();
        // Always run with synchronous starts of `async` functions.
        // If we want to make this dependent on other parameters or flags,
        // this flag could be become conditional.
        content = dartdevcHtml(nameNoExt, jsDir, buildDir);
      }
    }

    var htmlPath = '$tempDir/test.html';
    new File(htmlPath).writeAsStringSync(content);

    // TODO(floitsch): Hack. When running the 2.0 tests always start
    // async functions synchronously.
    if (suiteName.endsWith("_2") &&
        configuration.compiler == Compiler.dart2js) {
      if (optionsFromFile == null) {
        optionsFromFile = const <String, dynamic>{
          'sharedOptions': const ['--sync-async']
        };
      } else {
        optionsFromFile = new Map<String, dynamic>.from(optionsFromFile);
        var sharedOptions = optionsFromFile['sharedOptions'];
        if (sharedOptions == null) {
          sharedOptions = const <String>['--sync-async'];
        } else {
          sharedOptions = sharedOptions.toList();
          sharedOptions.insert(0, "--sync-async");
        }
        optionsFromFile['sharedOptions'] = sharedOptions;
      }
    }

    // Construct the command(s) that compile all the inputs needed by the
    // browser test. For running Dart in DRT, this will be noop commands.
    var commands = <Command>[];

    void addCompileCommand(String fileName, String toPath) {
      switch (configuration.compiler) {
        case Compiler.dart2js:
          commands.add(_dart2jsCompileCommand(
              fileName, toPath, tempDir, optionsFromFile));
          break;

        case Compiler.dartdevc:
        case Compiler.dartdevk:
          var ddcOptions = optionsFromFile["sharedOptions"] as List<String>;
          ddcOptions.addAll(optionsFromFile["ddcOptions"] as List<String>);
          commands.add(configuration.compilerConfiguration.createCommand(
              fileName, toPath, ddcOptions, environmentOverrides));
          break;

        default:
          assert(false);
      }
    }

    addCompileCommand(fileName, jsWrapperFileName);

    // Some tests require compiling multiple input scripts.
    for (var name in optionsFromFile['otherScripts'] as List<String>) {
      var namePath = new Path(name);
      var fromPath = info.filePath.directoryPath.join(namePath).toNativePath();
      var toPath = new Path('$tempDir/${namePath.filename}.js').toNativePath();
      addCompileCommand(fromPath, toPath);
    }

    if (info.optionsFromFile['isMultiHtmlTest'] as bool) {
      // Variables for browser multi-tests.
      var subtestNames = info.optionsFromFile['subtestNames'] as List<String>;
      for (var subtestName in subtestNames) {
        _enqueueSingleBrowserTest(commands, info, '$testName/$subtestName',
            subtestName, expectations[subtestName], htmlPath);
      }
    } else {
      _enqueueSingleBrowserTest(
          commands, info, testName, null, expectations[testName], htmlPath);
    }
  }

  /// Enqueues a single browser test, or a single subtest of an HTML multitest.
  void _enqueueSingleBrowserTest(
      List<Command> commands,
      TestInformation info,
      String testName,
      String subtestName,
      Set<Expectation> expectations,
      String htmlPath) {
    // Construct the command that executes the browser test.
    commands = commands.toList();

    var htmlPathSubtest = _createUrlPathFromFile(new Path(htmlPath));
    var fullHtmlPath = _uriForBrowserTest(htmlPathSubtest, subtestName);

    if (configuration.runtime == Runtime.drt) {
      var dartFlags = <String>[];
      var contentShellOptions = ['--no-timeout', '--run-layout-test'];

      // Disable the GPU under Linux and Dartium. If the GPU is enabled,
      // Chrome may send a termination signal to a test.  The test will be
      // terminated if a machine (bot) doesn't have a GPU or if a test is
      // still running after a certain period of time.
      if (configuration.system == System.linux &&
          configuration.runtime == Runtime.drt) {
        contentShellOptions.add('--disable-gpu');
        // TODO(terry): Roll 50 need this in conjection with disable-gpu.
        contentShellOptions.add('--disable-gpu-early-init');
      }

      commands.add(Command.contentShell(contentShellFilename, fullHtmlPath,
          contentShellOptions, dartFlags, environmentOverrides));
    } else {
      commands.add(Command.browserTest(fullHtmlPath, configuration,
          retry: !isNegative(info)));
    }

    var fullName = testName;
    if (subtestName != null) fullName += "/$subtestName";
    enqueueNewTestCase(fullName, commands, expectations, info);
  }

  void _enqueueHtmlTest(HtmlTestInformation info, String testName) {
    var compiler = configuration.compiler;
    var runtime = configuration.runtime;

    if (compiler == Compiler.dartdevc || compiler == Compiler.dartdevk) {
      // TODO(rnystrom): Support this for dartdevc (#29919).
      print("Ignoring $testName on ${compiler.name} since HTML tests are not "
          "implemented for that compiler yet.");
      return;
    }

    // HTML tests work only with the browser controller.
    if (!runtime.isBrowser || runtime == Runtime.drt) return;

    var compileToJS = compiler == Compiler.dart2js;

    var filePath = info.filePath;
    var tempDir = createOutputDirectory(filePath);
    var tempUri = new Uri.file('$tempDir/');
    var contents = html_test.getContents(info, compileToJS);
    var commands = <Command>[];

    void fail(String message) {
      var msg = "$message: ${info.filePath}";
      DebugLogger.warning(msg);
      contents = html_test.makeFailingHtmlFile(msg);
    }

    if (info.scripts.length > 0) {
      var testUri = new Uri.file(filePath.toNativePath());
      for (var scriptPath in info.scripts) {
        if (!scriptPath.endsWith('.dart') && !scriptPath.endsWith('.js')) {
          fail('HTML test scripts must be dart or javascript: $scriptPath');
          break;
        }

        var uri = Uri.parse(scriptPath);
        if (uri.isAbsolute) {
          fail('HTML test scripts must have relative paths: $scriptPath');
          break;
        }

        if (uri.pathSegments.length > 1) {
          fail('HTML test scripts must be in test directory: $scriptPath');
          break;
        }

        var script = testUri.resolveUri(uri);
        var copiedScript = tempUri.resolveUri(uri);
        if (compiler == Compiler.none || scriptPath.endsWith('.js')) {
          new File.fromUri(copiedScript)
              .writeAsStringSync(new File.fromUri(script).readAsStringSync());
        } else {
          var destination = copiedScript.toFilePath();
          if (compileToJS) {
            destination = destination.replaceFirst(dartExtension, '.js');
          }

          assert(compiler == Compiler.dart2js);

          commands.add(_dart2jsCompileCommand(
              script.toFilePath(), destination, tempDir, info.optionsFromFile));
        }
      }
    }

    var htmlFile = tempUri.resolve(filePath.filename);
    new File.fromUri(htmlFile).writeAsStringSync(contents);

    var htmlPath = _createUrlPathFromFile(new Path(htmlFile.toFilePath()));
    var fullHtmlPath = _uriForBrowserTest(htmlPath);
    commands.add(Command.browserHtmlTest(
        fullHtmlPath, configuration, info.expectedMessages,
        retry: !isNegative(info)));
    enqueueNewTestCase(
        testName, commands, testExpectations.expectations(testName), info);
  }

  /// Creates a [Command] to compile a single .dart file using dart2js.
  Command _dart2jsCompileCommand(String inputFile, String outputFile,
      String dir, Map<String, dynamic> optionsFromFile) {
    var args = <String>[];

    if (compilerPath.endsWith('.dart')) {
      // Run the compiler script via the Dart VM.
      args.add(compilerPath);
    }

    args.addAll(configuration.standardOptions);
    args.addAll(configuration.dart2jsOptions);

    var packages = packagesArgument(optionsFromFile['packageRoot'] as String,
        optionsFromFile['packages'] as String);
    if (packages != null) args.add(packages);

    args.add('--out=$outputFile');
    args.add(inputFile);

    var options = optionsFromFile['sharedOptions'] as List<String>;
    if (options != null) args.addAll(options);
    options = optionsFromFile['dart2jsOptions'] as List<String>;
    if (options != null) args.addAll(options);

    return Command.compilation(Compiler.dart2js.name, outputFile,
        dart2JsBootstrapDependencies, compilerPath, args, environmentOverrides,
        alwaysCompile: !useSdk);
  }

  String get contentShellFilename {
    if (configuration.drtPath != null) return configuration.drtPath;

    if (Platform.operatingSystem == 'macos') {
      final path = dartDir.append(
          '/client/tests/drt/Content Shell.app/Contents/MacOS/Content Shell');
      return path.toNativePath();
    }
    return dartDir.append('client/tests/drt/content_shell').toNativePath();
  }

  List<String> commonArgumentsFromFile(
      Path filePath, Map<String, dynamic> optionsFromFile) {
    var args = configuration.standardOptions.toList();

    String packages = packagesArgument(optionsFromFile['packageRoot'] as String,
        optionsFromFile['packages'] as String);
    if (packages != null) {
      args.add(packages);
    }
    args.addAll(additionalOptions(filePath));
    if (configuration.compiler == Compiler.dart2analyzer) {
      args.add('--format=machine');
      args.add('--no-hints');
      if (configuration.previewDart2) args.add("--preview-dart-2");
      if (configuration.noPreviewDart2) args.add("--no-preview-dart-2");

      if (filePath.filename.contains("dart2js") ||
          filePath.directoryPath.segments().last.contains('html_common')) {
        args.add("--use-dart2js-libraries");
      }
    }

    var isMultitest = optionsFromFile["isMultitest"] as bool;
    var dartOptions = optionsFromFile["dartOptions"] as List<String>;

    assert(!isMultitest || dartOptions == null);
    args.add(filePath.toNativePath());
    if (dartOptions != null) {
      args.addAll(dartOptions);
    }

    return args;
  }

  String packagesArgument(String packageRootFromFile, String packagesFromFile) {
    if (packageRootFromFile == 'none' || packagesFromFile == 'none') {
      return null;
    } else if (packagesFromFile != null) {
      return '--packages=$packagesFromFile';
    } else if (packageRootFromFile != null) {
      return '--package-root=$packageRootFromFile';
    } else {
      return null;
    }
  }

  /**
   * Special options for individual tests are currently specified in various
   * ways: with comments directly in test files, by using certain imports, or by
   * creating additional files in the test directories.
   *
   * Here is a list of options that are used by 'test.dart' today:
   *   - Flags can be passed to the vm process that runs the test by adding a
   *   comment to the test file:
   *
   *     // VMOptions=--flag1 --flag2
   *
   *   - Flags can be passed to dart2js, vm or dartdevc by adding a comment to
   *   the test file:
   *
   *     // SharedOptions=--flag1 --flag2
   *
   *   - Flags can be passed to dart2js by adding a comment to the test file:
   *
   *     // dart2jsOptions=--flag1 --flag2
   *
   *   - Flags can be passed to the dart script that contains the test also
   *   using comments, as follows:
   *
   *     // DartOptions=--flag1 --flag2
   *
   *   - Extra environment variables can be passed to the process that runs
   *   the test by adding comment(s) to the test file:
   *
   *     // Environment=ENV_VAR1=foo bar
   *     // Environment=ENV_VAR2=bazz
   *
   *   - For tests that depend on compiling other files with dart2js (e.g.
   *   isolate tests that use multiple source scripts), you can specify
   *   additional files to compile using a comment too, as follows:
   *
   *     // OtherScripts=file1.dart file2.dart
   *
   *   - You can indicate whether a test is treated as a web-only test by
   *   using an explicit import to a part of the dart:html library:
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
  Map<String, dynamic> readOptionsFromFile(Uri uri) {
    if (uri.path.endsWith('.dill')) {
      return optionsFromKernelFile();
    } else if ("$uri".startsWith("$co19SuiteLocation") ||
        "$uri".startsWith("$legacyCo19SuiteLocation")) {
      return readOptionsFromCo19File(uri);
    }
    RegExp testOptionsRegExp = new RegExp(r"// VMOptions=(.*)");
    RegExp environmentRegExp = new RegExp(r"// Environment=(.*)");
    RegExp otherScriptsRegExp = new RegExp(r"// OtherScripts=(.*)");
    RegExp otherResourcesRegExp = new RegExp(r"// OtherResources=(.*)");
    RegExp packageRootRegExp = new RegExp(r"// PackageRoot=(.*)");
    RegExp packagesRegExp = new RegExp(r"// Packages=(.*)");
    RegExp isolateStubsRegExp = new RegExp(r"// IsolateStubs=(.*)");
    // TODO(gram) Clean these up once the old directives are not supported.
    RegExp domImportRegExp = new RegExp(
        r"^[#]?import.*dart:(html|web_audio|indexed_db|svg|web_sql)",
        multiLine: true);

    var bytes = new File.fromUri(uri).readAsBytesSync();
    String contents = decodeUtf8(bytes);
    bytes = null;

    // Find the options in the file.
    var result = <List<String>>[];
    List<String> dartOptions;
    List<String> sharedOptions;
    List<String> dart2jsOptions;
    List<String> ddcOptions;
    Map<String, String> environment;
    String packageRoot;
    String packages;

    List<String> wordSplit(String s) =>
        s.split(' ').where((e) => e != '').toList();

    List<String> singleListOfOptions(String name) {
      var matches = new RegExp('// $name=(.*)').allMatches(contents);
      List<String> options;
      for (var match in matches) {
        if (options != null) {
          throw new Exception(
              'More than one "// $name=" line in test ${uri.toFilePath()}');
        }
        options = wordSplit(match[1]);
      }
      return options;
    }

    var matches = testOptionsRegExp.allMatches(contents);
    for (var match in matches) {
      result.add(wordSplit(match[1]));
    }
    if (result.isEmpty) result.add([]);

    dartOptions = singleListOfOptions('DartOptions');
    sharedOptions = singleListOfOptions('SharedOptions');
    dart2jsOptions = singleListOfOptions('dart2jsOptions');
    ddcOptions = singleListOfOptions('dartdevcOptions');

    matches = environmentRegExp.allMatches(contents);
    for (var match in matches) {
      final String envDef = match[1];
      final int pos = envDef.indexOf('=');
      final String name = (pos < 0) ? envDef : envDef.substring(0, pos);
      final String value = (pos < 0) ? '' : envDef.substring(pos + 1);
      environment ??= <String, String>{};
      environment[name] = value;
    }

    matches = packageRootRegExp.allMatches(contents);
    for (var match in matches) {
      if (packageRoot != null || packages != null) {
        throw new Exception(
            'More than one "// Package... line in test ${uri.toFilePath()}');
      }
      packageRoot = match[1];
      if (packageRoot != 'none') {
        // PackageRoot=none means that no packages or package-root option
        // should be given. Any other value overrides package-root and
        // removes any packages option.  Don't use with // Packages=.
        packageRoot =
            uri.resolveUri(new Uri.directory(packageRoot)).toFilePath();
      }
    }

    matches = packagesRegExp.allMatches(contents);
    for (var match in matches) {
      if (packages != null || packageRoot != null) {
        throw new Exception(
            'More than one "// Package..." line in test ${uri.toFilePath()}');
      }
      packages = match[1];
      if (packages != 'none') {
        // Packages=none means that no packages or package-root option
        // should be given. Any other value overrides packages and removes
        // any package-root option. Don't use with // PackageRoot=.
        packages = uri.resolveUri(new Uri.file(packages)).toFilePath();
      }
    }

    var otherScripts = <String>[];
    matches = otherScriptsRegExp.allMatches(contents);
    for (var match in matches) {
      otherScripts.addAll(wordSplit(match[1]));
    }

    var otherResources = <String>[];
    matches = otherResourcesRegExp.allMatches(contents);
    for (var match in matches) {
      otherResources.addAll(wordSplit(match[1]));
    }

    var isMultitest = multiTestRegExp.hasMatch(contents);
    var isMultiHtmlTest = multiHtmlTestRegExp.hasMatch(contents);
    var isolateMatch = isolateStubsRegExp.firstMatch(contents);
    var isolateStubs = isolateMatch != null ? isolateMatch[1] : '';
    var containsDomImport = domImportRegExp.hasMatch(contents);

    var subtestNames = <String>[];
    var matchesIter = multiHtmlTestGroupRegExp.allMatches(contents).iterator;
    while (matchesIter.moveNext() && isMultiHtmlTest) {
      var fullMatch = matchesIter.current.group(0);
      subtestNames.add(fullMatch.substring(fullMatch.indexOf("'") + 1));
    }

    // TODO(rnystrom): During the migration of the existing tests to Dart 2.0,
    // we have a number of tests that used to both generate static type warnings
    // and also validate some runtime behavior in an implementation that
    // ignores those warnings. Those warnings are now errors. The test code
    // validates the runtime behavior can and should be removed, but the code
    // that causes the static warning should still be preserved since that is
    // part of our coverage of the static type system.
    //
    // The test needs to indicate that it should have a static error. We could
    // put that in the status file, but that makes it confusing because it
    // would look like implementations that *don't* report the error are more
    // correct. Eventually, we want to have a notation similar to what front_end
    // is using for the inference tests where we can put a comment inside the
    // test that says "This specific static error should be reported right by
    // this token."
    //
    // That system isn't in place yet, so we do a crude approximation here in
    // test.dart. If a test contains `/*@compile-error=`, which matches the
    // beginning of the tag syntax that front_end uses, then we assume that
    // this test must have a static error somewhere in it.
    //
    // Redo this code once we have a more precise test framework for detecting
    // and locating these errors.
    var hasSyntaxError = contents.contains("/*@syntax-error=");
    var hasCompileError =
        hasSyntaxError || contents.contains("/*@compile-error=");

    return {
      "vmOptions": result,
      "sharedOptions": sharedOptions ?? <String>[],
      "dart2jsOptions": dart2jsOptions ?? <String>[],
      "ddcOptions": ddcOptions ?? <String>[],
      "dartOptions": dartOptions,
      "environment": environment,
      "packageRoot": packageRoot,
      "packages": packages,
      "hasSyntaxError": hasSyntaxError,
      "hasCompileError": hasCompileError,
      "hasRuntimeError": false,
      "hasStaticWarning": false,
      "otherScripts": otherScripts,
      "otherResources": otherResources,
      "isMultitest": isMultitest,
      "isMultiHtmlTest": isMultiHtmlTest,
      "subtestNames": subtestNames,
      "isolateStubs": isolateStubs,
      "containsDomImport": containsDomImport
    };
  }

  Map<String, dynamic> optionsFromKernelFile() {
    return const {
      "vmOptions": const [const <String>[]],
      "sharedOptions": const <String>[],
      "dart2jsOptions": const <String>[],
      "dartOptions": null,
      "packageRoot": null,
      "packages": null,
      "hasSyntaxError": false,
      "hasCompileError": false,
      "hasRuntimeError": false,
      "hasStaticWarning": false,
      "otherScripts": const [],
      "isMultitest": false,
      "isMultiHtmlTest": false,
      "subtestNames": const [],
      "isolateStubs": '',
      "containsDomImport": false,
    };
  }

  List<List<String>> getVmOptions(Map<String, dynamic> optionsFromFile) {
    const compilers = const [
      Compiler.none,
      Compiler.dartk,
      Compiler.dartkp,
      Compiler.precompiler,
      Compiler.appJit
    ];

    const runtimes = const [
      Runtime.none,
      Runtime.dartPrecompiled,
      Runtime.vm,
      Runtime.drt,
      Runtime.contentShellOnAndroid
    ];

    var needsVmOptions = compilers.contains(configuration.compiler) &&
        runtimes.contains(configuration.runtime);
    if (!needsVmOptions) return [[]];
    return optionsFromFile['vmOptions'] as List<List<String>>;
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
  Map<String, dynamic> readOptionsFromCo19File(Uri uri) {
    String contents = decodeUtf8(new File.fromUri(uri).readAsBytesSync());

    bool hasSyntaxError = contents.contains("@syntax-error");
    bool hasCompileError =
        hasSyntaxError || contents.contains("@compile-error");
    bool hasRuntimeError = contents.contains("@runtime-error");
    bool hasStaticWarning = contents.contains("@static-warning");
    bool isMultitest = multiTestRegExp.hasMatch(contents);

    return {
      "vmOptions": <List>[[]],
      "sharedOptions": <String>[],
      "dart2jsOptions": <String>[],
      "dartOptions": null,
      "packageRoot": null,
      "hasSyntaxError": hasSyntaxError,
      "hasCompileError": hasCompileError,
      "hasRuntimeError": hasRuntimeError,
      "hasStaticWarning": hasStaticWarning,
      "otherScripts": <String>[],
      "otherResources": <String>[],
      "isMultitest": isMultitest,
      "isMultiHtmlTest": false,
      "subtestNames": <String>[],
      "isolateStubs": '',
      "containsDomImport": false,
    };
  }
}

/// Used for testing packages in on off settings, i.e., we pass in the actual
/// directory that we want to test.
class PKGTestSuite extends StandardTestSuite {
  PKGTestSuite(Configuration configuration, Path directoryPath)
      : super(configuration, directoryPath.filename, directoryPath,
            ["$directoryPath/.status"],
            isTestFilePredicate: (f) => f.endsWith('_test.dart'),
            recursive: true);

  void _enqueueBrowserTest(Path packageRoot, packages, TestInformation info,
      String testName, Map<String, Set<Expectation>> expectations) {
    var filePath = info.filePath;
    var dir = filePath.directoryPath;
    var nameNoExt = filePath.filenameWithoutExtension;
    var customHtmlPath = dir.append('$nameNoExt.html');
    var customHtml = new File(customHtmlPath.toNativePath());
    if (!customHtml.existsSync()) {
      super._enqueueBrowserTest(
          packageRoot, packages, info, testName, expectations);
    } else {
      var fullPath = _createUrlPathFromFile(customHtmlPath);
      var command = Command.browserTest(fullPath, configuration,
          retry: !isNegative(info));
      enqueueNewTestCase(testName, [command], expectations[testName], info);
    }
  }
}

class AnalyzeLibraryTestSuite extends StandardTestSuite {
  static Path _libraryPath(Configuration configuration) =>
      new Path(configuration.useSdk
          ? '${configuration.buildDirectory}/dart-sdk'
          : 'sdk');

  bool get listRecursively => true;

  AnalyzeLibraryTestSuite(Configuration configuration)
      : super(configuration, 'analyze_library', _libraryPath(configuration),
            ['tests/lib/analyzer/analyze_library.status']);

  List<String> additionalOptions(Path filePath, {bool showSdkWarnings}) =>
      const ['--fatal-warnings', '--fatal-type-errors', '--sdk-warnings'];

  Future enqueueTests() {
    var group = new FutureGroup();

    var dir = new Directory(suiteDir.append('lib').toNativePath());
    if (dir.existsSync()) {
      enqueueDirectory(dir, group);
    }

    return group.future;
  }

  bool isTestFile(String filename) {
    // NOTE: We exclude tests and patch files for now.
    return filename.endsWith(".dart") &&
        !filename.endsWith("_test.dart") &&
        !filename.contains("_internal/js_runtime/lib");
  }
}
