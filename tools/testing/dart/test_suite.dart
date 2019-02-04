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
import 'http_server.dart';
import 'multitest.dart';
import 'path.dart';
import 'repository.dart';
import 'summary_report.dart';
import 'test_configurations.dart';
import 'test_runner.dart';
import 'utils.dart';

RegExp multiHtmlTestGroupRegExp = new RegExp(r"\s*[^/]\s*group\('[^,']*");
RegExp multiHtmlTestRegExp = new RegExp(r"useHtmlIndividualConfiguration\(\)");
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
  final TestConfiguration configuration;
  final String suiteName;
  final List<String> statusFilePaths;
  // This function is set by subclasses before enqueueing starts.
  Function doTest;
  Map<String, String> _environmentOverrides;

  TestSuite(this.configuration, this.suiteName, this.statusFilePaths) {
    _environmentOverrides = {
      'DART_CONFIGURATION': configuration.configurationDirectory,
    };
    if (Platform.isWindows) {
      _environmentOverrides['DART_SUPPRESS_WER'] = '1';
      if (configuration.copyCoreDumps) {
        _environmentOverrides['DART_CRASHPAD_HANDLER'] =
            new Path(buildDir + '/crashpad_handler.exe')
                .absolute
                .toNativePath();
      }
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
        info: info);
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
    if (configuration.testList != null &&
        !configuration.testList.contains(displayName)) {
      return;
    }

    if (configuration.hotReload || configuration.hotReloadRollback) {
      // Handle reload special cases.
      if (expectations.contains(Expectation.compileTimeError) ||
          testCase.hasCompileError) {
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

  bool isNegative(TestInformation info) =>
      info.hasCompileError ||
      info.hasRuntimeError && configuration.runtime != Runtime.none;

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
    var legacy = configuration.noPreviewDart2 ? '-legacy' : '';
    var minified = configuration.isMinified ? '-minified' : '';
    var sdk = configuration.useSdk ? '-sdk' : '';
    var dirName = "${configuration.compiler.name}-${configuration.runtime.name}"
        "$checked$legacy$minified$sdk";
    return createGeneratedTestDirectoryHelper("tests", dirName, testPath);
  }

  String createCompilationOutputDirectory(Path testPath) {
    var checked = configuration.isChecked ? '-checked' : '';
    var legacy = configuration.noPreviewDart2 ? '-legacy' : '';
    var minified = configuration.isMinified ? '-minified' : '';
    var csp = configuration.isCsp ? '-csp' : '';
    var sdk = configuration.useSdk ? '-sdk' : '';
    var dirName = "${configuration.compiler.name}"
        "$checked$legacy$minified$csp$sdk";
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

  VMTestSuite(TestConfiguration configuration)
      : dartDir = Repository.dir.toNativePath(),
        super(configuration, "vm", ["runtime/tests/vm/vm.status"]) {
    var binarySuffix = Platform.operatingSystem == 'windows' ? '.exe' : '';

    // For running the tests we use the given '$runnerName' binary
    targetRunnerPath = '$buildDir/run_vm_tests$binarySuffix';

    // For listing the tests we use the '$runnerName.host' binary if it exists
    // and use '$runnerName' if it doesn't.
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
    var fullName = 'cc/$testName';
    var expectations = testExpectations.expectations(fullName);

    var args = configuration.standardOptions.toList();
    if (configuration.compilerConfiguration.previewDart2) {
      final dfePath = new Path("$buildDir/gen/kernel-service.dart.snapshot")
          .absolute
          .toNativePath();
      // '--dfe' has to be the first argument for run_vm_test to pick it up.
      args.insert(0, '--dfe=$dfePath');
    }
    if (expectations.contains(Expectation.crash)) {
      args.insert(0, '--suppress-core-dump');
    }

    args.add(testName);

    var command = Command.process(
        'run_vm_unittest', targetRunnerPath, args, environmentOverrides);
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
  bool hasStaticWarning;
  String multitestKey;

  TestInformation(
      this.filePath,
      this.originTestPath,
      this.optionsFromFile,
      this.hasSyntaxError,
      this.hasCompileError,
      this.hasRuntimeError,
      this.hasStaticWarning,
      {this.multitestKey: ''}) {
    assert(filePath.isAbsolute);
  }
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
  final bool listRecursively;
  final List<String> extraVmOptions;
  List<Uri> _dart2JsBootstrapDependencies;
  Set<String> _testListPossibleFilenames;
  RegExp _selectorFilenameRegExp;

  StandardTestSuite(TestConfiguration configuration, String suiteName,
      Path suiteDirectory, List<String> statusFilePaths,
      {bool recursive: false})
      : dartDir = Repository.dir,
        listRecursively = recursive,
        suiteDir = Repository.dir.join(suiteDirectory),
        extraVmOptions = configuration.vmOptions,
        super(configuration, suiteName, statusFilePaths) {
    // Initialize _dart2JsBootstrapDependencies
    if (!useSdk) {
      _dart2JsBootstrapDependencies = [];
    } else {
      _dart2JsBootstrapDependencies = [
        Uri.base
            .resolveUri(new Uri.directory(buildDir))
            .resolve('dart-sdk/bin/snapshots/dart2js.dart.snapshot')
      ];
    }

    // Initialize _testListPossibleFilenames
    if (configuration.testList != null) {
      _testListPossibleFilenames = Set<String>();
      for (String s in configuration.testList) {
        if (s.startsWith("$suiteName/")) {
          s = s.substring(s.indexOf('/') + 1);
          _testListPossibleFilenames
              .add(suiteDir.append('$s.dart').toNativePath());
          // If the test is a multitest, the filename doesn't include the label.
          if (s.lastIndexOf('/') != -1) {
            s = s.substring(0, s.lastIndexOf('/'));
            _testListPossibleFilenames
                .add(suiteDir.append('$s.dart').toNativePath());
          }
        }
      }
    }

    // Initialize _selectorFilenameRegExp
    String pattern = configuration.selectors[suiteName].pattern;
    if (pattern.contains("/")) {
      String lastPart = pattern.substring(pattern.lastIndexOf("/") + 1);
      // If the selector is a multitest name ending in a number or 'none'
      // we also accept test file names that don't contain that last part.
      if (int.tryParse(lastPart) != null || lastPart == "none") {
        pattern = pattern.substring(0, pattern.lastIndexOf("/"));
      }
    }
    _selectorFilenameRegExp = new RegExp(pattern);
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
      TestConfiguration configuration, Path directory) {
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
        recursive: true);
  }

  List<Uri> get dart2JsBootstrapDependencies => _dart2JsBootstrapDependencies;

  /// The default implementation assumes a file is a test if
  /// it ends in "_test.dart".
  bool isTestFile(String filename) => filename.endsWith("_test.dart");

  List<String> additionalOptions(Path filePath) => [];

  Future forEachTest(
      Function onTest, Map<String, List<TestInformation>> testCache,
      [VoidFunction onDone]) async {
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
    // This is an optimization to avoid scanning and generating extra tests.
    // The definitive check against configuration.testList is performed in
    // TestSuite.enqueueNewTestCase().
    if (_testListPossibleFilenames?.contains(filename) == false) return;
    // Note: have to use Path instead of a filename for matching because
    // on Windows we need to convert backward slashes to forward slashes.
    // Our display test names (and filters) are given using forward slashes
    // while filenames on Windows use backwards slashes.
    final Path filePath = Path(filename);
    if (!_selectorFilenameRegExp.hasMatch(filePath.toString())) return;

    if (!isTestFile(filename)) return;

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
        info.hasCompileError) {
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

      var expectations = testExpectations.expectations(testName);
      var isCrashExpected = expectations.contains(Expectation.crash);
      var commands = makeCommands(info, vmOptionsVariant, allVmOptions,
          commonArguments, isCrashExpected);
      enqueueNewTestCase(testName, commands, expectations, info);
    }
  }

  List<Command> makeCommands(TestInformation info, int vmOptionsVariant,
      List<String> vmOptions, List<String> args, bool isCrashExpected) {
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

    if (info.hasCompileError &&
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
    var extraEnv = info.optionsFromFile['environment'] as Map<String, String>;
    if (extraEnv != null) {
      environment = new Map.from(environment)..addAll(extraEnv);
    }

    return commands
      ..addAll(configuration.runtimeConfiguration.computeRuntimeCommands(this,
          compilationArtifact, runtimeArguments, environment, isCrashExpected));
  }

  CreateTest makeTestCaseCreator(Map<String, dynamic> optionsFromFile) {
    return (Path filePath, Path originTestPath,
        {bool hasSyntaxError,
        bool hasCompileError,
        bool hasRuntimeError,
        bool hasStaticWarning: false,
        String multitestKey}) {
      // Cache the test information for each test case.
      var info = new TestInformation(filePath, originTestPath, optionsFromFile,
          hasSyntaxError, hasCompileError, hasRuntimeError, hasStaticWarning,
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
        content = dartdevcHtml(nameNoExt, jsDir, configuration.compiler);
      }
    }

    var htmlPath = '$tempDir/test.html';
    new File(htmlPath).writeAsStringSync(content);

    // Construct the command(s) that compile all the inputs needed by the
    // browser test.
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

    commands.add(Command.browserTest(fullHtmlPath, configuration,
        retry: !isNegative(info)));

    var fullName = testName;
    if (subtestName != null) fullName += "/$subtestName";
    enqueueNewTestCase(fullName, commands, expectations, info);
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
    if (configuration.compiler == Compiler.dart2js) {
      if (configuration.noPreviewDart2) {
        args.add("--no-preview-dart-2");
      } else {
        args.add("--preview-dart-2");
      }
    }

    return Command.compilation(Compiler.dart2js.name, outputFile,
        dart2JsBootstrapDependencies, compilerPath, args, environmentOverrides,
        alwaysCompile: !useSdk);
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

      if (filePath.filename.contains("dart2js") ||
          filePath.directoryPath.segments().last.contains('html_common')) {
        args.add("--use-dart2js-libraries");
      }
    }

    if (configuration.compiler == Compiler.dart2js) {
      if (configuration.noPreviewDart2) {
        args.add("--no-preview-dart-2");
      } else {
        args.add("--preview-dart-2");
      }
    }

    var isMultitest = optionsFromFile["isMultitest"] as bool;
    var dartOptions = optionsFromFile["dartOptions"] as List<String>;

    assert(!isMultitest || dartOptions == null);
    args.add(filePath.toNativePath());
    if (dartOptions != null) {
      // TODO(ahe): Because we add [dartOptions] here,
      // [CompilerConfiguration.computeCompilerArguments] has to discard them
      // later. Perhaps it would be simpler to pass [dartOptions] to
      // [CompilerConfiguration.computeRuntimeArguments].
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
   *   - Most tests are not web tests, but can (and will be) wrapped within
   *   an HTML file and another script file to test them also on browser
   *   environments (e.g. language and corelib tests are run this way).
   *   We deduce that if a file with the same name as the test, but ending in
   *   .html instead of .dart exists, the test was intended to be a web test
   *   and no wrapping is necessary.
   *
   *   - 'test.dart' assumes tests fail if
   *   the process returns a non-zero exit code (in the case of web tests, we
   *   check for PASS/FAIL indications in the test output).
   *
   * This method is static as the map is cached and shared amongst
   * configurations, so it may not use [configuration].
   */
  Map<String, dynamic> readOptionsFromFile(Uri uri) {
    if (uri.path.endsWith('.dill')) {
      return optionsFromKernelFile();
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
    if (result.isEmpty) result.add(<String>[]);

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
    final hasSyntaxError = contents.contains("@syntax-error");
    final hasCompileError =
        hasSyntaxError || contents.contains("@compile-error");
    final hasRuntimeError = contents.contains("@runtime-error");
    final hasStaticWarning = contents.contains("@static-warning");

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
      "hasRuntimeError": hasRuntimeError,
      "hasStaticWarning": hasStaticWarning,
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
      Compiler.dartkb,
      Compiler.dartkp,
      Compiler.precompiler,
      Compiler.appJit,
      Compiler.appJitk,
    ];

    const runtimes = const [Runtime.none, Runtime.dartPrecompiled, Runtime.vm];

    var needsVmOptions = compilers.contains(configuration.compiler) &&
        runtimes.contains(configuration.runtime);
    if (!needsVmOptions) return [[]];
    return optionsFromFile['vmOptions'] as List<List<String>>;
  }
}

/// Used for testing packages in one-off settings, i.e., we pass in the actual
/// directory that we want to test.
class PKGTestSuite extends StandardTestSuite {
  PKGTestSuite(TestConfiguration configuration, Path directoryPath)
      : super(configuration, directoryPath.filename, directoryPath,
            ["$directoryPath/.status"],
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
  static Path _libraryPath(TestConfiguration configuration) =>
      new Path(configuration.useSdk
          ? '${configuration.buildDirectory}/dart-sdk'
          : 'sdk');

  bool get listRecursively => true;

  AnalyzeLibraryTestSuite(TestConfiguration configuration)
      : super(configuration, 'analyze_library', _libraryPath(configuration),
            ['tests/lib_2/analyzer/analyze_library.status']);

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
